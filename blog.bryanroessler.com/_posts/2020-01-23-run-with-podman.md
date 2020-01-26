---
layout: post
title: Developing in containers using podman and container management scripts
subtitle: Now with systemd!
#bigimg: /img/path.jpg
tags: [atom, podman, containers, ide, systemd, run-with-podman]
---

### Overview

In this tutorial we will be using Atom's [build package](https://atom.io/packages/build) (although you are free to use your own IDE) and a container management script to run files/commands on default system images using podman. We will go one step further by enabling systemd support in our build environment. We will also provide the option of masking the program's output from the host using unnamed volumes.

### Introduction

It is important to remember that a development environment can be just as important as the code itself. Over time, our development environment morphs into a unique beast that are specific to each user. Therefore, it is imperative to test your programs in several default environments prior to distribution.

In the past, this was performed on virtual machines (VMs) that contained a default installation of the distribution that you were targeting. Thanks to their snapshotting abilities it was fairly trivial to restore distributions to their default state for software testing. However, this method had its drawbacks:

* The default state was never the *current* default state for long. VMs had to be continually upgraded via their package managers to stay up-to-date with the development environment. They also needed to be modified in some cases (e.g. to enable sshd and allow authentication-less sudo) so deploying newer image versions required manual intervention
* Retroactive changes to existing VMs is difficult
* VMs are difficult to automate, requiring third-party tools (e.g. kickstart files, Ansible, etc.) to manage them
* Each VM gets its own IP address, which makes it difficult to automate ssh-based program building/script running
* VMs are computationally heavy. Their footprint is an entire deduplication of the host OS and its virtualization stack, in both memory and disk space. Taking and restoring snapshots is slow.
* There is a meaningful amount of performance loss between the hypervisor and disk i/o because it is handled using network protocols. For example, an Atom VM build command would normally look something like this:

```
cat {FILE_ACTIVE} | ssh fedora-build-machine.lan "cat > /tmp/{FILE_ACTIVE_NAME} ; mkdir -p {FILE_ACTIVE_NAME_BASE}; cd {FILE_ACTIVE_NAME_BASE}; chmod 755 /tmp/{FILE_ACTIVE_NAME} ; /tmp/{FILE_ACTIVE_NAME}"
```

In short, it takes a solid understanding of many different tools and decent scripting skills for a subpar experience using VMs as development environments.

### Enter containers

Containers alleviate all of the problems associated with using VMs to execute code.

They:

* Use standardized images of your target distributions and make it possible to execute commands directly on them
* Allow you to create your own custom base images using Dockerfiles, which are built on top of other rolling images that are automatically maintained
* Support several different networking options, such as automatically using the host network or operating via its own whitelisted service
* Perform great because the code is running on the same kernel as the OS
* Can be created and destroyed nearly instantaneously which makes them much better for executing frequent build commands (I'm a big F5'er)

### Podman and Toolbox

Podman is a container manager by Red Hat that is available on Fedora and CentOS and integral to Silverblue and CoreOS. Red Hat has also shipped some fun stuff built on top of Podman such as [Toolbox](https://fedoramagazine.org/a-quick-introduction-to-toolbox-on-fedora/) that combine system overlays and containers to provide seamless build environments for past and current CentOS and Fedora releases (theoretically you should be able to provide your own custom image although the documentation is currently scant). Toolbox will get you 90% of the way there to automated builds as long as you:

* only target Red Hat-based distributions
* don't develop or test systemd scripts or need to utilize existing systemd services (**systemd does not work in Toolbox**)
* are comfortable with having your entire $HOME exposed to your build environment
* don't need to nest toolboxes

Toolbox may make sense if you run separate instances of your IDE from *inside* the toolbox containers, but then you are just back to creating custom build environments within each container, only now separated from the host OS. Unfortunately, Toolbox does not support nesting containers so testing your code on default images from within a toolbox is impossible as of this moment. Additionally, if your scripts change environmental variables, they may be difficult to test as the toolbox is mutable.


### Prerequisites

1. You have a script or command to execute on build. Let's start with something easy like:
```bash
#!/usr/bin/env bash
# ./hello-pwd-ls.sh
echo "Hello!" | tee output/hello.txt
pwd
ls -al
exit $?
```
2. You have [Atom](https://atom.io/) and the [build](https://atom.io/packages/build) package installed
   * I won't pontificate on why I am using Atom and the build package as my example IDE. The podman commands I will highlight in this post will work equally as well using whichever IDE you choose to use in conjunction with its external build commands.
3. You are somewhat familiar with .atom-build.yml (or can copypasta)
3. You have podman installed


### Configuration


#### run-with-podman.sh

I created the following script to handle container execution depending on a few arguments. You can download it and place it in your path here:


Download [run-with-podman.sh](https://git.bryanroessler.com/bryan/run-with-podman/src/master/run-with-podman.sh) and install to `$HOME/.local/bin`:
```
wget -q -O "${HOME}/.local/bin/run-with-podman" "https://git.bryanroessler.com/bryan/run-with-podman/src/master/run-with-podman.sh"
```

If you prefer to copy-paste:
```bash
#!/usr/bin/env bash

# README; print this help message
print_help () {

    cat <<-'EOF'
Usage: run-with-podman.sh --file FILE [--file-path PATH] [--mode [0,1,2]]
                              [--mask-dir PATH] [--image IMAGE_NAME] [--force-systemd]
                              [--help] [--] $OPTIONS

    --file,-f FILE
        The local script to execute in the container (typically sent from your IDE)

    --file-path PATH
        Path that the script operates on (Default: the --file directory)

    --mode,-m 0,1,2
        0. Nonpersistent container (always recreate) (Default)
        1. Persistent container
        2. Recreate persistent container

    --mask-dir PATH
        Hide this directory from the host OS, store contents in the container only (Default: unset)
        (Useful for capturing output in the container only for easy reset)

    --image,-i IMAGE_NAME
        The name of the image to execute the script (Default: fedora:latest)

    --force-systemd
        Force container to init with systemd

    --help,-h
        Print this help message and exit

    -- [additional arguments to pass to --file FILE]
        Parsed as "quoted string"
EOF
}

# DEFAULTS
MODE="0"
IMAGE="fedora:latest"
SYSTEMD="on" # "on" is the podman default; "always" forces systemd init

# Parse input
function parse_input () {
    if options=$(getopt -o fmih -l file:,file-path:,mode:,mask-dir:,image:,force-systemd,help -- "$@"); then

        eval set -- "$options"
        while true; do
            case "$1" in
            --file| -f)
                shift
                FILE_ACTIVE="$1"
                ;;
            --file-path)
                shift
                FILE_ACTIVE_PATH="$1"
                ;;
            --mode| -m)
                shift
                MODE="$1"
                ;;
            --mask-dir)
                shift
                MASK_DIR="$1"
                ;;
            --image| -i)
                shift
                IMAGE="$1"
                ;;
            --force-systemd)
                SYSTEMD="always" # force systemd init
                ;;
            --help |-h)
                print_help
                exit $?
                ;;
            --)
                shift
                break
                ;;
            esac
            shift
        done
    else
        echo "Incorrect options provided"
        exit 1
    fi

    [[ -z $FILE_ACTIVE ]] && echo "You must provide a --file" && exit 1

    # If --file-path not set, extract FILE_ACTIVE_PATH from FILE_ACTIVE
    [[ -z $FILE_ACTIVE_PATH ]] && FILE_ACTIVE_PATH=${FILE_ACTIVE%/*}
    ! [[ -d "$FILE_ACTIVE_PATH" ]] &&

    # Pass any remaining positional arguments as script options
    OPTIONS=${*:$OPTIND}
}

# Get input
parse_input "${@}"

# Sanitize filename for unique container name
CLEAN="${FILE_ACTIVE//_/}" && CLEAN="${CLEAN//[^a-zA-Z0-9]/}" && CLEAN="${CLEAN,,}"

# Allow container access to the pwd
chcon -t container_file_t -R "${FILE_ACTIVE_PATH}"

# Nonpersistent container (always recreate)
if [[ $MODE == "0" ]]; then
    if podman container exists "atom-${CLEAN}-nonpersistent"; then
        podman rm -v -f "atom-${CLEAN}-nonpersistent"
    fi
    echo "Building in nonpersistent container: atom-${CLEAN}-nonpersistent"
    if [[ -n $MASK_DIR ]]; then
        podman run \
            -it \
            --systemd="${SYSTEMD}" \
            --name "atom-${CLEAN}-nonpersistent" \
            -v "${FILE_ACTIVE_PATH}:${FILE_ACTIVE_PATH}" \
            -v "${FILE_ACTIVE_PATH}/${MASK_DIR}" \
            -w "${FILE_ACTIVE_PATH}" \
            "${IMAGE}" \
            /bin/bash -c "chmod 755 ${FILE_ACTIVE} && ${FILE_ACTIVE} ${OPTIONS}"
    else
        podman run \
            -it \
            --systemd="${SYSTEMD}" \
            --name "atom-${CLEAN}-nonpersistent" \
            -v "${FILE_ACTIVE_PATH}:${FILE_ACTIVE_PATH}" \
            -w "${FILE_ACTIVE_PATH}" \
            "${IMAGE}" \
            /bin/bash -c "chmod 755 ${FILE_ACTIVE} && ${FILE_ACTIVE} ${OPTIONS}"
    fi
# Persistent container
elif [[ $MODE == "1" ]]; then
    echo "Reusing container: atom-${CLEAN}-persistent"
    if podman container exists "atom-${CLEAN}-persistent"; then
        echo "Using existing container!"
        podman exec "atom-${CLEAN}-persistent" \
        /bin/bash -c "chmod 755 {FILE_ACTIVE} && {FILE_ACTIVE}"
    else
        if [[ -n $MASK_DIR ]]; then
            podman run \
            -it \
            --systemd="${SYSTEMD}" \
            --name "atom-${CLEAN}-persistent" \
            -v "{FILE_ACTIVE_PATH}:{FILE_ACTIVE_PATH}" \
            -v "{FILE_ACTIVE_PATH}/${MASK_DIR}" \
            -w "{FILE_ACTIVE_PATH}" \
            "${IMAGE}" \
            /bin/bash -c "chmod 755 {FILE_ACTIVE} && {FILE_ACTIVE} ${OPTIONS}"
        else
            podman run \
            -it \
            --systemd="${SYSTEMD}" \
            --name "atom-${CLEAN}-persistent" \
            -v "{FILE_ACTIVE_PATH}:{FILE_ACTIVE_PATH}" \
            -w "{FILE_ACTIVE_PATH}" \
            "${IMAGE}" \
            /bin/bash -c "chmod 755 {FILE_ACTIVE} && {FILE_ACTIVE} ${OPTIONS}"
        fi
    fi
# Recreate persistent container
elif [[ $MODE == "2" ]]; then
    echo "Building in container: atom-${CLEAN}-persistent"
    if podman container exists "atom-${CLEAN}-persistent"; then
        echo "Container exists! Resetting container."
        podman rm -v -f "atom-${CLEAN}-persistent"
    fi
    if [[ -n $MASK_DIR ]]; then
        podman run \
        -it \
        --systemd="${SYSTEMD}" \
        --name "atom-${CLEAN}-persistent" \
        -v "{FILE_ACTIVE_PATH}:{FILE_ACTIVE_PATH}" \
        -v "{FILE_ACTIVE_PATH}/${MASK_DIR}" \
        -w "{FILE_ACTIVE_PATH}" \
        "${IMAGE}" \
        /bin/bash -c "chmod 755 {FILE_ACTIVE} && {FILE_ACTIVE} ${OPTIONS}"
    else
        podman run \
        -it \
        --systemd="${SYSTEMD}" \
        --name "atom-${CLEAN}-persistent" \
        -v "{FILE_ACTIVE_PATH}:{FILE_ACTIVE_PATH}" \
        -w "{FILE_ACTIVE_PATH}" \
        "${IMAGE}" \
        /bin/bash -c "chmod 755 {FILE_ACTIVE} && {FILE_ACTIVE} ${OPTIONS}"
    fi
fi

```

There are several things to highlight in this script:

1. The filename is first sanitized so that it can be used to generate a unique container name.
2. Next, we edit SELinux permissions on our `pwd` to allow the container full access to our build directory. Editing SELinux permissions is always a balance between ease-of-use and security and I find setting the container_file_t flag is a nice balance. If your script doesn't do much file i/o it may be possible to run it by only altering permissions on `$FILE_ACTIVE`.
3. According to the mode we either remove and recreate or create a new container
4. We mount the `pwd` in the container
5. If `OUTPUT=0, `we mask the output directory `-v "{FILE_ACTIVE_PATH}/${OUTPUT_DIR}"` by mounting an unnamed volume, so that output is only stored in the container and not on the host filesystem. You can repeat this as many times as necessary to exclude other subdirectories in your build directory.
6. Enable `--systemd=always` if you plan on interacting with `systemctl` using your script. The default `on` state will only enable systemd when the command passed to the container is `/usr/sbin/init`. Since it is not possible to pass more than one command and we must pass our script, this should be set to `always`.
7. Make sure to make the script executable in the container using `chmod 755`


##### `--file` and `--file-path`

The file or command that you want to run in the container. If missing, `--file-path` will be generated from the `pwd` of the `--file`.

This can be a script running a list of commands (e.g. build script) or a single command to be executed.

##### `--mode`

0. Nonpersistent container (always recreate) (Default)
1. Persistent container
2. Recreate persistent container

##### `--mask-dir`

Optionally, one can mask output from the host system (so that it only resides in a container volume) using `--mask-dir`.  As demonstrated in the [prerequisites](#prerequisites), it is important to have your program output to the `--` specified in your `.atom-build.yml` (in this case 'output'). This provides you the ability to optionally mask the output directory with an unnamed volume so that no files are actually written to the host. This has two benefits:

* If the script is configured to overwrite existing output, it may threaten a live system (like a website or any other running process that depends on the script output)
* If the script is configured to not overwrite existing output, the script may not run correctly

Output masking gives you the power to control these variables independently of one another by writing output to the container only.

##### `--force-systemd`

Typically, containers are used to run microservices where *n* containers is equal to *n* processes. While that is good design for microservices, it is still possible to use a process manager to create multi-service containers for purposes other than microservices (in this case a development environment).

If you are going to release software that integrates with systemd, it is certainly worthwhile to test your services beforehand in a containerized environment. By using `podman` along with the `--systemd=always` option mentioned [above](#atom-container-build.sh), we can initialize an interactive systemd process *and* execute our script.

##### `--image`

The container image to be used to execute the command.


#### .atom-build.yml

In your project directory (next to your script), create the following `.atom-build.yml` file in order to call our script using the appropriate arguments whenever a build is triggered.

```yaml
cmd: 'run-with-podman.sh --file {FILE_ACTIVE} --file-path {FILE_ACTIVE_PATH} --mode 0 --mask-dir output --image fedora:latest --force-systemd'
name: 'Nonpersistent F31 container w/ systemd'
targets:
  Persistent F31 container w/ systemd:
    cmd: 'run-with-podman.sh --file {FILE_ACTIVE} --file-path {FILE_ACTIVE_PATH} --mode 1 --mask-dir output --image fedora:latest --force-systemd'
  Reset and run persistent F31 container w/ systemd:
    cmd: 'run-with-podman.sh --file {FILE_ACTIVE} --file-path {FILE_ACTIVE_PATH} --mode 2 --mask-dir output --image fedora:latest --force-systemd'
  Nonpersistent F31 container w/ output & systemd:
    cmd: 'run-with-podman.sh --file {FILE_ACTIVE} --file-path {FILE_ACTIVE_PATH} --mode 0 --image fedora:latest --force-systemd'
  Persistent F31 container w/ output & systemd:
    cmd: 'run-with-podman.sh --file {FILE_ACTIVE} --file-path {FILE_ACTIVE_PATH} --mode 1 --image fedora:latest --force-systemd'
  Reset and run persistent F31 container w/ output & systemd:
    cmd: 'run-with-podman.sh --file {FILE_ACTIVE} --file-path {FILE_ACTIVE_PATH} --mode 2 --image fedora:latest --force-systemd'
```

This `.atom-build.yml` can be as complicated as you need it to be, in fact you can perform all of the same shell functions as `atom-container-build.sh` in a `cmd` argument; however, I find it cleaner and easier to break the shell script out of YAML and pass simple arguments instead.

There are plenty of other options available in the build package to set the environment of your script, or you can pass them as arguments following `--` in your `cmd`.

You can also run build using any external build file, you are not just limited to executing the `{FILE_ACTIVE}`.

Save your files and run the appropriate build command on your script! Now you're developing in containers!

### Conclusions

Developing in containers can be streamlined using tools like `podman` and container management scripts like I provided [earlier](#run-with-podman.sh).
