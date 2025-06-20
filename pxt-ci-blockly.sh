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

# Check if branch starts with "blockly-" to skip blockly setup
SKIP_BLOCKLY=false
if [[ "$CF_PAGES_BRANCH" == blockly-* ]]; then
  SKIP_BLOCKLY=true
  echo "Branch starts with 'blockly-', skipping blockly and plugin setup"
fi

# This is a thin CLI intended to be installed globally
npm install -g pxt

if [ "$SKIP_BLOCKLY" = false ]; then
  # Blockly develop branch
  (
    cd ../
    git clone git@github.com:microbit-matt-hillsdon/blockly.git
    cd blockly
    git checkout preview || git checkout develop
    npm install
    npm run package
    cd dist
    # Fix up paths
    perl -pi -e 's/blockly\//.\//g' index.js
    npm link
  )
  
  # Blockly keyboard experiment plugin setup
  # Skip if installed from tgz
  if ! grep -qe "@blockly/keyboard-experiment.*tgz" -qe "@blockly/keyboard-navigation.*tgz" package.json; then
    (
      cd ../
      git clone git@github.com:microbit-matt-hillsdon/blockly-keyboard-experimentation.git
      cd blockly-keyboard-experimentation
      git checkout preview || echo "No preview branch, using default"
      npm install
      npm link blockly
      npm run build
      npm pack
    )
    cp ../blockly-keyboard-experimentation/blockly-keyboard-navigation*.tgz .
  fi
fi

# pxt project setup
npm install

if [ "$SKIP_BLOCKLY" = false ]; then
  npm install ./blockly-keyboard-navigation*.tgz
  npm link blockly
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
