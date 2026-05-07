#!/usr/bin/env bash
# @testcase: usage-nodejs-r15-crypto-pbkdf2-sync-deterministic
# @title: Node.js crypto.pbkdf2Sync produces deterministic output for fixed inputs
# @description: Calls crypto.pbkdf2Sync('password','salt-r15',1000,16,'sha256') twice and asserts both invocations return Buffers of length 16 with byte-identical contents (PBKDF2 is deterministic for fixed inputs).
# @timeout: 60
# @tags: usage, crypto, nodejs
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/script.js" <<'JS'
const assert = require('assert');
const crypto = require('crypto');
const a = crypto.pbkdf2Sync('password', 'salt-r15', 1000, 16, 'sha256');
const b = crypto.pbkdf2Sync('password', 'salt-r15', 1000, 16, 'sha256');
assert.strictEqual(a.length, 16);
assert.strictEqual(b.length, 16);
assert.ok(a.equals(b));
console.log('OK pbkdf2Sync');
JS

node "$tmpdir/script.js" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'OK pbkdf2Sync'
