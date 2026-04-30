#!/usr/bin/env bash
# @testcase: usage-nodejs-buffer-concat-large
# @title: Node.js Buffer.concat large consistency
# @description: Concatenates many Buffer chunks with Buffer.concat and verifies sha256 equals the digest of the original payload.
# @timeout: 180
# @tags: usage, nodejs, buffer
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

node >"$tmpdir/out" <<'JS'
const assert = require('assert');
const crypto = require('crypto');

const totalSize = 1 << 20; // 1 MiB
const payload = crypto.randomBytes(totalSize);
const expected = crypto.createHash('sha256').update(payload).digest('hex');

const chunkSize = 4096;
const chunks = [];
for (let i = 0; i < payload.length; i += chunkSize) {
  chunks.push(payload.subarray(i, Math.min(i + chunkSize, payload.length)));
}

const joined = Buffer.concat(chunks, totalSize);
assert.strictEqual(joined.length, totalSize);
assert.ok(joined.equals(payload), 'concat mismatch');
const got = crypto.createHash('sha256').update(joined).digest('hex');
assert.strictEqual(got, expected);

console.log('OK concat', totalSize, chunks.length, got.slice(0, 12));
JS

validator_assert_contains "$tmpdir/out" 'OK concat 1048576 256'
