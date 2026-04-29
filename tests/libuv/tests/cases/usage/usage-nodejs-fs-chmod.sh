#!/usr/bin/env bash
# @testcase: usage-nodejs-fs-chmod
# @title: Node.js fs chmod
# @description: Changes file permissions with fs.chmod and verifies the resulting mode bits.
# @timeout: 180
# @tags: usage, nodejs, fs
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-nodejs-fs-chmod"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

FILE_PATH="$tmpdir/file.txt" node >"$tmpdir/out" <<'JS'
const fs = require('fs');
const path = process.env.FILE_PATH;
fs.writeFileSync(path, 'chmod payload\n');
fs.chmod(path, 0o640, (error) => {
  if (error) throw error;
  const mode = fs.statSync(path).mode & 0o777;
  console.log(mode.toString(8));
});
JS
validator_assert_contains "$tmpdir/out" '640'
