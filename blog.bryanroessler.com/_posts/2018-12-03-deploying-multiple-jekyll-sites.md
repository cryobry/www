---
layout: post
title: Mass deploying Jekyll using git hooks
subtitle:
#bigimg: /img/path.jpg
tags: [jekyll, git]
---

As advertised, Jekyll is an excellent choice for building a simple (and secure!) personal or small business website. However, when compared to its better-known and bigger brethren, scaling the Jekyll workflow to manage multiple sites or subdomains is not readily apparent. In this post I will outline a git-based workflow to build and deploy a website with multiple subdomains.

I prefer storing my work in version controlled git repositories in order to keep track of modifications and to assist in the backup and restore of my environment and data on multiple machines. One of the machines that I use to store this data [is also the cloud storage VPS that I use to run this site.]({% post_url 2018-06-22-strategies-for-maximizing-vps %}) The storage VPS holds the [bare website repositories](https://git.bryanroessler.com/bryan/www) that I can push to and pull from my other development machines. Since my website repositories contain jekyll site code, all that I need to do is to instruct the VPS to build and deploy that code!

There are three steps that need to occur for this to happen seamlessly after the git repos have been created (which is outside the scope of this post).

On the client:

1. Push website changes to the server

On the server:
2. Clone the bare repo into a local working git repo
3. Build the jekyll site
4. Deploy it to the production directory

The server-side steps can be automated by utilizing git post-receive hooks (i.e. run immediately after the client initiates a push).

Although the process is straightforward, carrying out those steps repeatedly for multiple subdomains or websites can quickly become tedious.

For larger websites, I prefer using nested git repositories to simplify website deployment. This strategy used to be poorly supported in git and most IDEs, but recently they've gained wider support. A nested git repository works just as one would expect: a nested git repository (what I refer to as a subgit) can contain its own settings (for instance, pointing at upstream branches) while residing within a parent git repository that can be used to backup and deploy *en masse*. This is very helpful because the subgit can be managed independently from other portions of the website. For example, upstream changes can be merged into the subgit site without disturbing the state of the other git repositories.

By combining the subgit strategy with some structured naming conventions it is possible to push, build, and deploy multiple subdomains or sites using a single git push from the client!

Example:

~~~bash
#!/usr/bin/env bash
"/var/lib/git/gogs/gogs" hook --config='/var/lib/git/gogs/conf/app.ini' post-receive

GIT_DIR="$(pwd)"
TMP_GIT_DIR="/tmp/${GIT_DIR##*/}"

if [[ ! -d "${TMP_GIT_DIR}" ]]; then
    git clone "${GIT_DIR}" "${TMP_GIT_DIR}"
    cd "${TMP_GIT_DIR}" || exit $?
else
    cd "${TMP_GIT_DIR}" || exit $?
    unset GIT_DIR
    git fetch --all
    git reset --hard origin/main
    git pull
fi

for site in *.*/; do
    deploy_dir="/var/www/${site}"
    if [[ ! -d "$deploy_dir" ]]; then
        mkdir -p "$deploy_dir"
        chgrp -R "$deploy_dir"
        chmod g+s "$deploy_dir"
    fi
    pushd "${site}" || exit $?
    ruby -S bundle install --deployment
    ruby -S bundle exec jekyll build --destination "$deploy_dir"
    popd || exit $?
done

exit 0

~~~
