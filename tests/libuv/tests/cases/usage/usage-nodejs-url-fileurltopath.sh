#!/usr/bin/env bash
# @testcase: usage-nodejs-url-fileurltopath
# @title: Node.js url.fileURLToPath
# @description: Converts a file:// URL to a filesystem path with url.fileURLToPath and verifies the absolute path round-trips through string and URL forms.
# @timeout: 120
# @tags: usage, nodejs, url
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-nodejs-url-fileurltopath"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/script.js" <<'JS'
const { fileURLToPath } = require('url');
const fromString = fileURLToPath('file:///tmp/example%20file.txt');
if (fromString !== '/tmp/example file.txt') {
  throw new Error('string form: ' + fromString);
}
const fromUrl = fileURLToPath(new URL('file:///var/log/syslog'));
if (fromUrl !== '/var/log/syslog') {
  throw new Error('URL form: ' + fromUrl);
}
console.log('fileurltopath ok string=' + fromString);
console.log('fileurltopath ok url=' + fromUrl);
JS

node "$tmpdir/script.js" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'fileurltopath ok string=/tmp/example file.txt'
validator_assert_contains "$tmpdir/out" 'fileurltopath ok url=/var/log/syslog'
