#!/usr/bin/env bash
# @testcase: usage-nodejs-zlib-constants-best-speed-compression
# @title: Node.js zlib constants Z_BEST_SPEED and Z_BEST_COMPRESSION
# @description: Verifies zlib.constants exposes Z_BEST_SPEED=1 and Z_BEST_COMPRESSION=9, then deflates a payload at each level and confirms both round trip back to the original bytes.
# @timeout: 180
# @tags: usage, nodejs, zlib
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/run.js" <<'JS'
const assert = require('assert');
const zlib = require('zlib');

assert.strictEqual(zlib.constants.Z_BEST_SPEED, 1);
assert.strictEqual(zlib.constants.Z_BEST_COMPRESSION, 9);

const payload = Buffer.from('zlib-constants ' + 'pattern '.repeat(96), 'utf8');

const fast = zlib.deflateSync(payload, { level: zlib.constants.Z_BEST_SPEED });
const small = zlib.deflateSync(payload, { level: zlib.constants.Z_BEST_COMPRESSION });

assert.ok(fast.length > 0);
assert.ok(small.length > 0);

const fastBack = zlib.inflateSync(fast);
const smallBack = zlib.inflateSync(small);

assert.ok(fastBack.equals(payload), 'fast roundtrip mismatch');
assert.ok(smallBack.equals(payload), 'small roundtrip mismatch');
assert.ok(small.length <= fast.length, 'best-compression should not be larger than best-speed');

console.log('OK zlib-constants speed=%d compression=%d fast=%d small=%d', zlib.constants.Z_BEST_SPEED, zlib.constants.Z_BEST_COMPRESSION, fast.length, small.length);
JS

node "$tmpdir/run.js" >"$tmpdir/out"

validator_assert_contains "$tmpdir/out" 'OK zlib-constants speed=1 compression=9'
