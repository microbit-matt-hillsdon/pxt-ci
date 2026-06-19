#!/usr/bin/env bash
# Hacky CI to build the Blockly playground (from the Blockly monorepo) in CF
# Pages and similar environments.
#
# Intended to be run via
#
# curl -sL https://github.com/microbit-matt-hillsdon/pxt-ci/raw/refs/heads/main/blockly-ci.sh | bash -s
#
# Run from the monorepo root (the package.json with "workspaces": ["packages/*"]).
# Requires Node >=22 (set NODE_VERSION=22 in the CF Pages environment).
#
# CF Pages settings:
#   Build command:            curl -sL .../blockly-ci.sh | bash -s
#   Build output directory:   public
#
# The deployed playground is served at /tests/playground.html; "/" redirects there.

set -euxo pipefail
export CI=true

# Root install hoists workspace deps into the repo-root node_modules.
npm install

# gulp build (the blockly package's "build" script) = minify + langfiles.
# When served from a non-localhost host the playground loads compressed mode,
# i.e. dist/*_compressed.js, so we need the minify output, not just build/src.
npm run build -w blockly

# Assemble the static site. The playground imports paths relative to
# packages/blockly/tests/ (../build, ../dist via the page ROOT, and
# ../node_modules/@blockly/...), so mirror that layout under public/.
# -L dereferences the workspace symlinks under node_modules.
PKG=packages/blockly
OUT=public
rm -rf "$OUT"
mkdir -p "$OUT/node_modules/@blockly"
cp -RL "$PKG/tests" "$OUT/tests"
cp -RL "$PKG/build" "$OUT/build"
cp -RL "$PKG/dist"  "$OUT/dist"

# npm may hoist workspace deps to the repo-root node_modules instead of the
# package's own, so look in both. The playground loads these at runtime.
copy_dep() {
  for base in "$PKG/node_modules/@blockly/$1" "node_modules/@blockly/$1"; do
    if [ -e "$base" ]; then cp -RL "$base" "$OUT/node_modules/@blockly/$1"; return; fi
  done
  echo "Could not find @blockly/$1 in node_modules" >&2; exit 1
}
copy_dep dev-tools
copy_dep theme-modern

# Land visitors on the playground.
printf '/  /tests/playground.html  302\n' > "$OUT/_redirects"

cat << EOF > "$OUT/404.html"
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
