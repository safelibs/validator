#!/usr/bin/env bash
# @testcase: usage-nodejs-zlib-brotli-sync-roundtrip
# @title: Node.js zlib brotli sync round trip
# @description: Round trips a payload through zlib.brotliCompressSync and brotliDecompressSync and verifies byte equality.
# @timeout: 180
# @tags: usage, nodejs, zlib
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

node >"$tmpdir/out" <<'JS'
const assert = require('assert');
const zlib = require('zlib');

const payload = Buffer.from('brotli-sync ' + 'data '.repeat(64), 'utf8');
const compressed = zlib.brotliCompressSync(payload);
assert.ok(Buffer.isBuffer(compressed));
assert.ok(compressed.length > 0);
assert.ok(compressed.length < payload.length, 'compressed not smaller');

const restored = zlib.brotliDecompressSync(compressed);
assert.ok(restored.equals(payload), 'roundtrip mismatch');

console.log('OK brotli-sync', payload.length, compressed.length);
JS

validator_assert_contains "$tmpdir/out" 'OK brotli-sync 332'
