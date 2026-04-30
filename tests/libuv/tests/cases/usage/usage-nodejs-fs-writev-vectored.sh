#!/usr/bin/env bash
# @testcase: usage-nodejs-fs-writev-vectored
# @title: Node.js fs.writev vectored write
# @description: Writes two buffers through Node.js fs.writev in a single call and verifies the concatenated file content.
# @timeout: 120
# @tags: usage, nodejs, fs
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-nodejs-fs-writev-vectored"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/script.js" <<'JS'
const fs = require('fs');
const path = require('path');
const tmpdir = process.argv[2];
const file = path.join(tmpdir, 'writev.bin');
const fd = fs.openSync(file, 'w');
const chunks = [Buffer.from('vector-'), Buffer.from('payload')];
fs.writev(fd, chunks, 0, (err, bytesWritten) => {
  try {
    if (err) throw err;
    if (bytesWritten !== 14) throw new Error('bytesWritten ' + bytesWritten);
    const body = fs.readFileSync(file, 'utf8');
    if (body !== 'vector-payload') throw new Error('body=' + body);
    console.log('writev ok ' + body);
  } finally {
    fs.closeSync(fd);
  }
});
JS

node "$tmpdir/script.js" "$tmpdir" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'writev ok vector-payload'
