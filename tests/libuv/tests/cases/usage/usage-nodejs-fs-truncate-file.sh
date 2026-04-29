#!/usr/bin/env bash
# @testcase: usage-nodejs-fs-truncate-file
# @title: nodejs fs truncate
# @description: Truncates a file to eight bytes through Node fs.truncateSync and verifies the shortened content.
# @timeout: 180
# @tags: usage, nodejs, filesystem
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-nodejs-fs-truncate-file"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

FILE_PATH="$tmpdir/data.txt" node >"$tmpdir/out" <<'JS'
const fs = require('fs');
const path = process.env.FILE_PATH;
fs.writeFileSync(path, 'truncate payload extra');
fs.truncateSync(path, 8);
console.log(fs.readFileSync(path, 'utf8'));
JS
validator_assert_contains "$tmpdir/out" 'truncate'
