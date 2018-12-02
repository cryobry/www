#!/usr/bin/env bash
# post-receive hook to build and deploy jekyll sites
"/var/lib/git/gogs/gogs" hook --config='/var/lib/git/gogs/conf/app.ini' post-receive

GIT_REPO="$(pwd)"
TMP_GIT_CLONE="/tmp/${GIT_REPO##*/}"

if [ ! -d "{$TMP_GIT_CLONE}" ]; then
    git clone "${GIT_REPO}" "$TMP_GIT_CLONE"
    cd "${TMP_GIT_CLONE}"
else
    cd "${TMP_GIT_CLONE}"

    # avoid breaking the build when force pushing
    git fetch --all
    git reset --hard origin/master

    git pull
fi

pushd "${TMP_GIT_CLONE}"

for site in *.*/; do
  [[ ! -d /var/www/${site} ]] && mkdir -p /var/www/${site} && chgrp -R /var/www/${site} && chmod g+s /var/www/${site}
  pushd ${site}
  bundle install --deployment
  bundle exec jekyll build --destination /var/www/${site}
  popd
done


exit
