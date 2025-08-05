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

if [[ "$CF_PAGES_BRANCH" == sr-* ]]; then
  echo "Branch starts with 'sr-', configuring dependencies for screenreader work"
  # We npm link blockly even though its unchanged because otherwise browserify
  # gets confused and packages two copies of blockly.
  (
    cd ../
    git clone git@github.com:google/blockly.git
    cd blockly
    git checkout blockly-v12.2.0
    npm install
    npm run package
    cd dist
    # Fix up paths
    perl -pi -e 's/blockly\//.\//g' index.js
    npm link
  )

  # This requires a specific plugin branch but is fine with 12.2.0 blockly.
  (
    cd ../
    git clone git@github.com:microbit-matt-hillsdon/blockly-keyboard-experimentation.git
    cd blockly-keyboard-experimentation
    # For the moment this is on Ben's fork, will change shortly to be a google branch.
    # git checkout add-screen-reader-support
    git remote add BenHenning git@github.com:BenHenning/blockly-keyboard-experimentation.git
    git fetch BenHenning
    git checkout --track BenHenning/introduce-initial-screen-reader-support
    npm install
    npm link blockly
    npm run build
  )
elif [[ "$CF_PAGES_BRANCH" == kb-* ]]; then
  echo "Branch starts with 'kb-', configuring dependencies for keyboard work"
  (
    cd ../
    git clone git@github.com:microbit-matt-hillsdon/blockly.git
    cd blockly
    git checkout kb-preview || git checkout develop
    npm install
    npm run package
    cd dist
    # Fix up paths
    perl -pi -e 's/blockly\//.\//g' index.js
    npm link
  )
  
  (
    cd ../
    git clone git@github.com:microbit-matt-hillsdon/blockly-keyboard-experimentation.git
    cd blockly-keyboard-experimentation
    git checkout kb-preview || echo "No kb-preview branch, using main"
    npm install
    npm link blockly
    npm run build
  )
fi

# This is a thin CLI intended to be installed globally
npm install -g pxt

# pxt project setup
npm install

# Link to whatever we checked out earlier
LINK_TARGETS=$(find ../ -maxdepth 1 -type d -name "blockly*" | tr '\n' ' ')
if [[ -n "$LINK_TARGETS" ]]; then
  npm link "$LINK_TARGETS"
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
