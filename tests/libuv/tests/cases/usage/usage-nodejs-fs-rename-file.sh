#!/usr/bin/env bash
# @testcase: usage-nodejs-fs-rename-file
# @title: Node.js fs rename file
# @description: Renames a file with Node.js fs.promises.rename and verifies the destination keeps the original payload.
# @timeout: 180
# @tags: usage, nodejs, filesystem
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-nodejs-fs-rename-file"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

TMPDIR="$tmpdir" node >"$tmpdir/out" <<'JS'
const fs = require('fs/promises');
const path = require('path');
const root = process.env.TMPDIR;
(async () => {
  const source = path.join(root, 'before.txt');
  const dest = path.join(root, 'after.txt');
  await fs.writeFile(source, 'rename payload\n');
  await fs.rename(source, dest);
  console.log((await fs.readFile(dest, 'utf8')).trim());
})();
JS
validator_assert_contains "$tmpdir/out" 'rename payload'
