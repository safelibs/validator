#!/usr/bin/env bash
# @testcase: usage-nodejs-fs-symlink-readlink
# @title: Node.js fs symlink readlink
# @description: Creates a symlink with Node.js fs APIs and verifies the link target with readlink.
# @timeout: 180
# @tags: usage, nodejs, fs
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-nodejs-fs-symlink-readlink"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

TMPDIR_PATH="$tmpdir" node >"$tmpdir/out" <<'JS'
const fs = require('fs');
const path = require('path');
const tmpdir = process.env.TMPDIR_PATH;
const target = path.join(tmpdir, 'target.txt');
const link = path.join(tmpdir, 'link.txt');
fs.writeFileSync(target, 'symlink payload\n');
fs.symlink(target, link, (error) => {
  if (error) throw error;
  fs.readlink(link, (readError, value) => {
    if (readError) throw readError;
    console.log(path.basename(value));
  });
});
JS
validator_assert_contains "$tmpdir/out" 'target.txt'
