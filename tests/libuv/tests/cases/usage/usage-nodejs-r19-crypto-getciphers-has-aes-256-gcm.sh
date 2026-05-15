#!/usr/bin/env bash
# @testcase: usage-nodejs-r19-crypto-getciphers-has-aes-256-gcm
# @title: Node.js crypto.getCiphers enumerates a list that includes aes-256-gcm
# @description: Calls crypto.getCiphers(), asserts the returned value is an Array with non-zero length, asserts every entry is a string, asserts 'aes-256-gcm' is present, and asserts 'aes-128-cbc' is present, confirming the OpenSSL-backed cipher enumeration surface exposed to Node.js (libuv-hosted) reports the canonical AEAD and CBC cipher identifiers.
# @timeout: 60
# @tags: usage, nodejs, crypto, getciphers, r19
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/script.js" <<'JS'
const assert = require('assert');
const crypto = require('crypto');
const list = crypto.getCiphers();
assert.ok(Array.isArray(list));
assert.ok(list.length > 0);
assert.ok(list.includes('aes-256-gcm'), 'missing aes-256-gcm');
assert.ok(list.includes('aes-128-cbc'), 'missing aes-128-cbc');
for (const c of list) {
  assert.strictEqual(typeof c, 'string');
}
console.log('OK ciphers.count=' + list.length);
JS

node "$tmpdir/script.js" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'OK ciphers.count='
