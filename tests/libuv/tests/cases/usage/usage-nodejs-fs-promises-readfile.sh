#!/usr/bin/env bash
# @testcase: usage-nodejs-fs-promises-readfile
# @title: Node.js fs promises readFile
# @description: Reads file content with the fs.promises API and verifies the resolved text payload.
# @timeout: 180
# @tags: usage, nodejs, filesystem
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-nodejs-fs-promises-readfile"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

FILE_PATH="$tmpdir/input.txt" node >"$tmpdir/out" <<'JS'
const fs = require('fs');
const path = process.env.FILE_PATH;
fs.writeFileSync(path, 'promises payload\n');
(async () => {
  const data = await fs.promises.readFile(path, 'utf8');
  console.log(data.trim());
})();
JS
validator_assert_contains "$tmpdir/out" 'promises payload'
