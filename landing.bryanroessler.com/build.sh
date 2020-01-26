#!/usr/bin/env bash

# build and deploy
#podman build \
#    --rm \
#    -it \
#    -v "$PWD:/srv/jekyll" \
#    -v "$PWD/vendor/bundle:/usr/local/bundle" \
#    -u 1000:1001 \
#    jekyll:latest \
#    bundle update

podman build -t atomjekylltemp2 "$1"
#podman run \
#    --rm \
#    -it \
#    -p 4001:4000 \
#    -v "${1}:/srv/jekyll" \
#    -v "${1}/vendor/bundle:/usr/local/bundle" \
#    localhost/atomjekylltemp2 \
#    bundle --version

podman run \
    --rm \
    -it \
    -v "${1}:/srv/jekyll" \
    -v "${1}/vendor/bundle:/usr/local/bundle" \
    localhost/atomjekylltemp2 \
    bundle --version

#podman rmi localhost/atomjekylltemp_2
