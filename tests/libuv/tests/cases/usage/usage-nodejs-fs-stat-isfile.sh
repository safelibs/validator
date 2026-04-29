#!/usr/bin/env bash
# @testcase: usage-nodejs-fs-stat-isfile
# @title: nodejs fs stat isFile
# @description: Calls Node fs.statSync on a regular file and verifies isFile returns true.
# @timeout: 180
# @tags: usage, nodejs, filesystem
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-nodejs-fs-stat-isfile"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

FILE_PATH="$tmpdir/file.txt" node >"$tmpdir/out" <<'JS'
const fs = require('fs');
const path = process.env.FILE_PATH;
fs.writeFileSync(path, 'stat payload');
console.log(fs.statSync(path).isFile());
JS
validator_assert_contains "$tmpdir/out" 'true'
