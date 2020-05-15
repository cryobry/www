---
layout: post
title: 'podmanRun: a simple podman wrapper'
date: '2020-05-15 15:36'
tags:
  - podman
  - bash
  - fedora
  - containers
---

### Rationale

[In a previous post]({% post_url 2020-01-23-run-with-podman %}) I demonstrated the benefits of running and developing code in containers in order to maintain a clean and predictable development environment. After using [run-with-podman](https://git.bryanroessler.com/bryan/run-with-podman) for several months I found that there would often be edge cases requiring additional argument handling. In light of this, I have simplified run-with-podman into a [podman](https://podman.io/) cli wrapper that users can use to pass arguments directly to podman while maintaining the container management benefits of run-with-podman. It's a much simpler script that gives more power to users.

### Who is `podmanRun` intended for?

Anyone that wants to easily run programs in ephemeral or persistent containers. Personally, I use podmanRun in order to quickly test code in different Linux distributions, automate compilation, and deploy containerized build services including preprocessors and web servers.

### What does `podmanRun` actually do?

Not much, by design.

1.  Generates a unique container name based on the `--name` argument passed to `podman` within the `podmanRun` `--options` string. If no `--name` is specified in the `--options` string, podmanRun will generate a unique container name based on the concatenated options and commands passed by the user. Thus, if any options or commands are changed, a new container will be recreated regardless if `--mode=persistent` was set.
2.  Checks whether a container with that name already exists.
3.  If no matching container was found: the `--options` are passed directly to `podman run` and the commands are executed in the new container.
4.  If a matching container was found:
  - `--mode=recreate` will remove the existing container and run the commands in a new container using `podman run` with the provided `--options`.
  - `--mode=persistent` will run the commands in the existing container using `podman exec` and `--options` will be ignored.
3.  By default, the container is not removed afterwards (it will only be removed upon subsequent invocations of `podmanRun` using `--mode=recreate`) to allow the user to inspect the container. Containers can be automatically removed after execution by uncommenting the requisite line in `__main()`.

### Usage

For the complete list of up-to-date options, run `podmanRun --help`.
```
podmanRun [-m MODE] [-o OPTIONS] [COMMANDS [ARGS]...] [--help] [--debug]
```

##### Options

```text
--mode, -m MODE
    1. recreate (default) (remove container if it already exists and create a new one)
    2. persistent (reuse existing container if it exists)
--options, -o OPTIONS
    OPTIONS to pass to podman run/exec
--debug, -d
    Print debugging
--help, -h
    Print this help message and exit
```

Podman options can be passed to `--options` as a single string to be split on whitespace or passed multiple times discretely.

##### Examples

Run an ephemeral PHP webserver container using the current directory as webroot:
```
podmanRun -o "-p=8000:80 --name=php_script -v=$PWD:/var/www/html:z php:7.3-apache"
```

Run an ephemeral PHP webserver container using the current directory as webroot using IDE:
```
podmanRun -o "-p=8000:80 --name=php_{FILE_ACTIVE_NAME_BASE} -v={FILE_ACTIVE_PATH}:/var/www/html:z php:7.3-apache"
```

Run an ephemeral bash script:
```
podmanRun -o "--name=bash_script -v=$PWD:$PWD:z -w=$PWD debian:testing" ./script.sh
```

Run an ephemeral bash script using IDE:
```
podmanRun -o "--name=bash_{FILE_ACTIVE_NAME_BASE}" \
          -o "-v={FILE_ACTIVE_PATH}:{FILE_ACTIVE_PATH}:z" \
          -o "-w={FILE_ACTIVE_PATH}" \
          -o "debian:testing" \
          {FILE_ACTIVE} arg1 arg2
```

### Modes

podmanRun supports two modes: `recreate` and `persistent`. Recreate will always overwrite an existing container with the same name, while persistent will try to execute commands in an existing container (if found) using `podman exec`.



## Additional Info
Did you find `podmanRun` useful? [Buy me a coffee!](https://paypal.me/bryanroessler?locale.x=en_US)
