#!/usr/bin/env bash
# Hacky CI to build MakeCode in CF Pages and similar environments
#
# This script is intended for projects that fork and change pxt-microbit.
#
# Intended to be run via
# 
# curl -sL https://github.com/microbit-matt-hillsdon/pxt-ci/raw/refs/heads/main/pxt-microbit-ci.sh | bash -s
#
# Build output will be in public inside the pxt-microbit checkout.
# 

set -euxo pipefail
export CI=true

# This is a thin CLI intended to be installed globally
npm install -g pxt
# pxt appears to have a hidden dep on uglify-js
npm i -g uglify-js@3

npm install
PXT_ENV=production pxt staticpkg --minify
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

# Use a build path that's the default for CloudFlare 
mv built/packaged public
