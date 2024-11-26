#!/usr/bin/env bash
# Hacky CI to build MakeCode in CF Pages and similar environments
#
# This script is intended for projects that fork and change pxt but want to
# build pxt-microbit to try out the changes. It could easily be adapted to
# work the other way around.
#
# Intended to be run via
# 
# curl -sL https://github.com/microbit-matt-hillsdon/pxt-ci/raw/refs/heads/main/pxt-ci.sh | bash -s - master 
#
# ... where main is the ref of pxt-microbit to checkout (if omitted it defaults
# to master)
# 
# Build output will be in public inside the pxt checkout.
# 

set -euxo pipefail

# This is a thin CLI intended to be installed globally
npm install -g pxt

# pxt project setup
npm install
npm run build
npm link

# Sibling pxt-microbit project setup
(
  cd ../
  git clone git@github.com:microsoft/pxt-microbit.git
  cd pxt-microbit
  git checkout "${1:-master}"
  npm install
  # This will install all deps too
  npm link ../pxt
  pxt staticpkg
  cat << EOF > built/packaged/404.html
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>Not found</title>
  </head>
  <body>
    <p>Not found</p>
  </body>
</html>
EOF
)

# Use a build path that's the default for CloudFlare 
mv ../pxt-microbit/built/packaged public
