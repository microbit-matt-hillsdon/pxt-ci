#!/usr/bin/env bash
# Hacky CI to build MakeCode in CF Pages and similar environments
#
# This script is intended for projects that fork and change pxt but want to
# build pxt-microbit to try out the changes. It could easily be adapted to
# work the other way around.
#
# Intended to be run via
# 
# curl -sL https://github.com/microbit-matt-hillsdon/pxt-ci/raw/refs/heads/main/pxt-ci.sh | bash -s
#
# ... where main is the ref of pxt-microbit to checkout (if omitted it defaults
# to master)
# 
# Build output will be in public inside the pxt checkout.
# 

set -euxo pipefail
export CI=true

# This is a thin CLI intended to be installed globally
npm install -g pxt

# pxt project setup
npm install

# Blockly keyboard experiment plugin setup
# Skip if not present or installed from tgz
if grep -q "@blockly/keyboard-experiment" package.json && ! grep -q "@blockly/keyboard-experiment.*tgz" package.json; then
  (
    cd ../
    git clone git@github.com:microbit-matt-hillsdon/blockly-keyboard-experimentation.git
    cd blockly-keyboard-experimentation
    # Building our branch for the moment
    git checkout makecode-tweaks
    npm install
    npm run build
    # Doesn't work with npm link (dupe'd blockly deps?) so using tgz package for now
    npm pack
  )
  cp ../blockly-keyboard-experimentation/blockly-keyboard-experiment*.tgz .
  npm i ./blockly-keyboard-experiment*.tgz
fi

PXT_ENV=production npm run build
npm link

PXT_BRANCH="$CF_PAGES_BRANCH"
PXT_DIR="$PWD"

# Sibling pxt-microbit project setup
(
  cd ../
  git clone git@github.com:microbit-matt-hillsdon/pxt-microbit.git
  cd pxt-microbit
  git checkout "$PXT_BRANCH" || echo "No matching branch; falling back to master"
  npm install
  # This will install all deps too
  npm link "$PXT_DIR"
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
)

# Use a build path that's the default for CloudFlare 
mv ../pxt-microbit/built/packaged public
