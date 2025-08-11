#!/usr/bin/env bash
# Hacky CI to build the Blockly Keyboard Navigation experiment in CF Pages and
# similar environments.
#
# Intended to be run via
# 
# curl -sL
# https://github.com/microbit-matt-hillsdon/pxt-ci/raw/refs/heads/main/blockly-plugin-ci.sh
# | bash -s
#
# Build output in dist

set -euxo pipefail
export CI=true

npm install

if [[ "$CF_PAGES_BRANCH" == sr-* ]]; then
  echo "Branch starts with 'sr-', configuring dependencies for screenreader work"
  (
    cd ../
    git clone git@github.com:google/blockly.git
    cd blockly
    git checkout add-screen-reader-support-experimental
    npm install
    npm run package
    cd dist
    npm link
  )
  npm link blockly
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
    npm link
  )
  npm link blockly
fi

npm run build
npm run lint
npm run format:check
# not doing tests on CF for now
npm run ghpages

(
  cat << EOF > dist/404.html
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
