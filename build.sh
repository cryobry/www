#!/usr/bin/env bash
# Build the jekyll subdomains in a podman container

set -euo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SITES=(
  landing.bryanroessler.com
  blog.bryanroessler.com
  cv.bryanroessler.com
)

build_site() {
  local site="$1"

  podman run --rm -i \
    -v "$REPO_DIR:/app:Z" \
    -w "/app/$site" \
    docker.io/library/ruby:3.3.12-bookworm \
    bash -seuo pipefail <<- 'EOF'
			test -f Gemfile.lock
			gem install bundler --no-document
			bundle config set --local path /tmp/jekyll-bundle
			bundle install --jobs 4
			bundle exec jekyll build --destination /tmp/site
			test -f /tmp/site/index.html
		EOF
}

for site in "${SITES[@]}"; do
  build_site "$site"
done
