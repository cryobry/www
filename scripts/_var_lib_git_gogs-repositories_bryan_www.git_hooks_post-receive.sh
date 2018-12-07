#!/usr/bin/env bash
"/var/lib/git/gogs/gogs" hook --config='/var/lib/git/gogs/conf/app.ini' post-receive

GIT_DIR="$(pwd)"
TMP_GIT_DIR="/tmp/${GIT_DIR##*/}"

if [ ! -d "${TMP_GIT_DIR}" ]; then
    git clone "${GIT_DIR}" "${TMP_GIT_DIR}"
    cd "${TMP_GIT_DIR}"
else
    cd "${TMP_GIT_DIR}"
    unset GIT_DIR
    git fetch --all
    git reset --hard origin/master
    git pull
fi

for site in *.*/; do
  [ ! -d /var/www/${site} ] && mkdir -p /var/www/${site} && chgrp -R /var/www/${site} && chmod g+s /var/www/${site}
  pushd ${site}
  bundle install --deployment
  bundle exec jekyll build --destination /var/www/${site}
  popd
done


exit
