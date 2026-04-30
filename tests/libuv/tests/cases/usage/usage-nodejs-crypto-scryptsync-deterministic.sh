#!/usr/bin/env bash
# @testcase: usage-nodejs-crypto-scryptsync-deterministic
# @title: Node.js crypto.scryptSync deterministic output
# @description: Calls crypto.scryptSync twice with identical password and salt and verifies it is deterministic and differs when the salt changes.
# @timeout: 180
# @tags: usage, nodejs, crypto
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/run.js" <<'JS'
const assert = require('assert');
const crypto = require('crypto');

const a = crypto.scryptSync('correct horse battery staple', 'salt-a', 32);
const b = crypto.scryptSync('correct horse battery staple', 'salt-a', 32);
const c = crypto.scryptSync('correct horse battery staple', 'salt-b', 32);

assert.strictEqual(a.length, 32);
assert.ok(a.equals(b), 'same inputs must produce same key');
assert.ok(!a.equals(c), 'different salt must produce different key');

const hex = a.toString('hex');
assert.strictEqual(hex.length, 64);

console.log('OK scryptsync len=%d hex16=%s', a.length, hex.slice(0, 16));
JS

node "$tmpdir/run.js" >"$tmpdir/out"

validator_assert_contains "$tmpdir/out" 'OK scryptsync len=32 hex16='
