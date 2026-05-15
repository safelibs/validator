#!/usr/bin/env bash
# @testcase: usage-nodejs-r19-zlib-brotli-decompress-roundtrip
# @title: Node.js zlib.brotliCompressSync and brotliDecompressSync round-trip a repeated payload
# @description: Constructs a Buffer of 4096 bytes filled with byte 0x42, compresses it via zlib.brotliCompressSync, asserts the resulting compressed Buffer is smaller than the source (compression effective on a highly compressible repeated payload), decompresses the compressed Buffer via brotliDecompressSync, and asserts the recovered Buffer is exactly equal byte-for-byte to the original, exercising Node.js zlib brotli sync API.
# @timeout: 60
# @tags: usage, nodejs, zlib, brotli, roundtrip, r19
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/script.js" <<'JS'
const assert = require('assert');
const zlib = require('zlib');
const src = Buffer.alloc(4096, 0x42);
const compressed = zlib.brotliCompressSync(src);
assert.ok(compressed.length < src.length, 'compressed not smaller: ' + compressed.length);
const decompressed = zlib.brotliDecompressSync(compressed);
assert.deepStrictEqual(decompressed, src);
console.log('OK brotli.in=' + src.length + ' compressed=' + compressed.length);
JS

node "$tmpdir/script.js" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'OK brotli.in=4096'
