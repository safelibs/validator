#!/usr/bin/env bash
# @testcase: usage-nodejs-r15-zlib-deflate-inflate-roundtrip
# @title: Node.js zlib.deflateSync and inflateSync round-trip a payload byte-for-byte
# @description: Compresses a 256-byte deterministic payload with zlib.deflateSync, decompresses with zlib.inflateSync, and asserts the inflated output equals the original payload.
# @timeout: 60
# @tags: usage, zlib, nodejs
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/script.js" <<'JS'
const assert = require('assert');
const zlib = require('zlib');
const payload = Buffer.alloc(256);
for (let i = 0; i < payload.length; i++) payload[i] = i & 0xff;
const compressed = zlib.deflateSync(payload);
assert.ok(compressed.length > 0);
const inflated = zlib.inflateSync(compressed);
assert.ok(inflated.equals(payload));
console.log('OK zlib.roundtrip');
JS

node "$tmpdir/script.js" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'OK zlib.roundtrip'
