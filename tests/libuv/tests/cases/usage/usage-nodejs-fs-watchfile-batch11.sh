#!/usr/bin/env bash
# @testcase: usage-nodejs-fs-watchfile-batch11
# @title: Node.js fs watchFile
# @description: Watches a local file with fs.watchFile and verifies the change callback fires.
# @timeout: 180
# @tags: usage, nodejs, libuv
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-nodejs-fs-watchfile-batch11"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

FILE_PATH="$tmpdir/watchfile.txt" node >"$tmpdir/out" <<'JS'
const fs = require('fs');
const path = process.env.FILE_PATH;
fs.writeFileSync(path, 'before');
const timeout = setTimeout(() => {
  fs.unwatchFile(path);
  throw new Error('watchFile timeout');
}, 1000);
fs.watchFile(path, { interval: 20 }, (curr, prev) => {
  if (curr.mtimeMs !== prev.mtimeMs) {
    clearTimeout(timeout);
    fs.unwatchFile(path);
    console.log('watchfile-change');
  }
});
setTimeout(() => fs.writeFileSync(path, 'after'), 50);
JS
validator_assert_contains "$tmpdir/out" 'watchfile-change'
