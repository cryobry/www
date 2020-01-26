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

podman build -t atomjekylltemp .
podman run \
    --rm \
    -it \
    -p 4000:4000 \
    -v "$PWD:/srv/jekyll" \
    -v "$PWD/vendor/bundle:/usr/local/bundle" \
    localhost/atomjekylltemp

#podman rmi localhost/atomjekylltemp
