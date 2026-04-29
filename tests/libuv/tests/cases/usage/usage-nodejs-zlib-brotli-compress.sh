#!/usr/bin/env bash
# @testcase: usage-nodejs-zlib-brotli-compress
# @title: Node.js zlib Brotli round trip
# @description: Compresses and decompresses a payload with Node.js Brotli helpers and verifies the restored text.
# @timeout: 180
# @tags: usage, nodejs, zlib
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-nodejs-zlib-brotli-compress"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

node >"$tmpdir/out" <<'JS'
const zlib = require('zlib');
zlib.brotliCompress(Buffer.from('brotli payload'), (error, output) => {
  if (error) throw error;
  zlib.brotliDecompress(output, (decompressError, restored) => {
    if (decompressError) throw decompressError;
    console.log(restored.toString('utf8'));
  });
});
JS
validator_assert_contains "$tmpdir/out" 'brotli payload'
