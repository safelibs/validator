#!/usr/bin/env bash
# @testcase: usage-nodejs-crypto-randomfill-buffer-bytes
# @title: Node.js crypto.randomFillSync buffer fill
# @description: Allocates a zero-filled buffer, fills a slice via crypto.randomFillSync, and asserts the slice changed.
# @timeout: 180
# @tags: usage, crypto
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

node >"$tmpdir/out" <<'JS'
const assert = require('assert');
const crypto = require('crypto');

const buf = Buffer.alloc(64, 0);
const before = Buffer.from(buf);
const ret = crypto.randomFillSync(buf, 8, 32);
assert.strictEqual(ret, buf);

// Untouched regions remain zero.
for (let i = 0; i < 8; i++) assert.strictEqual(buf[i], 0);
for (let i = 40; i < 64; i++) assert.strictEqual(buf[i], 0);

// Target region changed (vanishingly small chance all 32 stayed zero).
assert.notStrictEqual(buf.slice(8, 40).compare(before.slice(8, 40)), 0);

console.log('OK randomfill', buf.length);
JS

validator_assert_contains "$tmpdir/out" 'OK randomfill 64'
