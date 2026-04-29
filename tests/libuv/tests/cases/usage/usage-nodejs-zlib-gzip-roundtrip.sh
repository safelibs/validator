#!/usr/bin/env bash
# @testcase: usage-nodejs-zlib-gzip-roundtrip
# @title: Node.js zlib gzip roundtrip
# @description: Compresses and restores a payload with Node.js zlib gzip and verifies the decompressed text output.
# @timeout: 180
# @tags: usage, nodejs, zlib
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-nodejs-zlib-gzip-roundtrip"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

node >"$tmpdir/out" <<'JS'
const zlib = require('zlib');
zlib.gzip(Buffer.from('gzip payload'), (error, compressed) => {
  if (error) throw error;
  zlib.gunzip(compressed, (restoreError, restored) => {
    if (restoreError) throw restoreError;
    console.log(restored.toString('utf8'));
  });
});
JS
validator_assert_contains "$tmpdir/out" 'gzip payload'
