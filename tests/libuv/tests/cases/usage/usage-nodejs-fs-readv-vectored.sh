#!/usr/bin/env bash
# @testcase: usage-nodejs-fs-readv-vectored
# @title: Node.js fs.readv vectored read
# @description: Reads a file through Node.js fs.readv into two buffers and verifies both segments are populated correctly.
# @timeout: 120
# @tags: usage, nodejs, fs
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-nodejs-fs-readv-vectored"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/script.js" <<'JS'
const fs = require('fs');
const path = require('path');
const tmpdir = process.argv[2];
const file = path.join(tmpdir, 'readv.bin');
fs.writeFileSync(file, 'AAAAABBBBB');
const fd = fs.openSync(file, 'r');
try {
  const a = Buffer.alloc(5);
  const b = Buffer.alloc(5);
  fs.readv(fd, [a, b], 0, (err, bytesRead) => {
    try {
      if (err) throw err;
      if (bytesRead !== 10) throw new Error('bytesRead ' + bytesRead);
      if (a.toString() !== 'AAAAA') throw new Error('a=' + a.toString());
      if (b.toString() !== 'BBBBB') throw new Error('b=' + b.toString());
      console.log('readv ok ' + a.toString() + '|' + b.toString());
    } finally {
      fs.closeSync(fd);
    }
  });
} catch (e) {
  fs.closeSync(fd);
  throw e;
}
JS

node "$tmpdir/script.js" "$tmpdir" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'readv ok AAAAA|BBBBB'
