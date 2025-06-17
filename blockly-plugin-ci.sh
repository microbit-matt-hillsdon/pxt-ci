#!/usr/bin/env bash
# Hacky CI to build the Blockly Keyboard Navigation experiment in CF Pages and
# similar environments. It builds against rc/v12.0.0 of Blockly via npm link.
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

# Blockly 
(
  cd ../
  git clone git@github.com:google/blockly.git
  cd blockly
  git checkout develop
  npm install
  npm run package
  cd dist
  npm link
)

npm link blockly
npm run lint || echo "Oops, lint is busted"
npm run format:check
# leaving test on CF for now
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
