#!/usr/bin/env bash
# @testcase: usage-nodejs-crypto-createsecretkey-raw
# @title: Node.js crypto.createSecretKey from raw bytes
# @description: Builds a KeyObject from raw bytes via crypto.createSecretKey and verifies the symmetric type and that an HMAC computed via the KeyObject matches one computed from the raw buffer.
# @timeout: 120
# @tags: usage, nodejs, crypto
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/run.js" <<'JS'
const assert = require('assert');
const crypto = require('crypto');

const raw = Buffer.alloc(32, 0x42);
const key = crypto.createSecretKey(raw);

assert.strictEqual(key.type, 'secret');
assert.strictEqual(key.symmetricKeySize, 32);

const exported = key.export();
assert.ok(exported.equals(raw), 'export must round trip raw bytes');

const viaKey = crypto.createHmac('sha256', key).update('msg').digest('hex');
const viaRaw = crypto.createHmac('sha256', raw).update('msg').digest('hex');
assert.strictEqual(viaKey, viaRaw);

console.log('OK secretkey type=%s size=%d hmac16=%s', key.type, key.symmetricKeySize, viaKey.slice(0, 16));
JS

node "$tmpdir/run.js" >"$tmpdir/out"

validator_assert_contains "$tmpdir/out" 'OK secretkey type=secret size=32 hmac16='
