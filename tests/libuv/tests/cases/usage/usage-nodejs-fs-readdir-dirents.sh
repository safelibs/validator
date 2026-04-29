#!/usr/bin/env bash
# @testcase: usage-nodejs-fs-readdir-dirents
# @title: Node.js fs readdir dirents
# @description: Lists directory entries with fs.readdir using Dirent objects and verifies both filenames are present.
# @timeout: 180
# @tags: usage, nodejs, filesystem
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-nodejs-fs-readdir-dirents"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

DIR_PATH="$tmpdir/list" node >"$tmpdir/out" <<'JS'
const fs = require('fs');
const path = process.env.DIR_PATH;
fs.mkdirSync(path, { recursive: true });
fs.writeFileSync(`${path}/alpha.txt`, 'alpha\n');
fs.writeFileSync(`${path}/beta.txt`, 'beta\n');
fs.readdir(path, { withFileTypes: true }, (error, entries) => {
  if (error) throw error;
  console.log(entries.map((entry) => entry.name).sort().join(','));
});
JS
validator_assert_contains "$tmpdir/out" 'alpha.txt,beta.txt'
