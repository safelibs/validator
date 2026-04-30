#!/usr/bin/env bash
# @testcase: usage-nodejs-crypto-ed25519-sign-verify
# @title: Node.js crypto ed25519 sign and verify
# @description: Generates an ed25519 keypair, signs a message with crypto.sign(null, ...), verifies it with crypto.verify, and asserts a tampered message fails verification.
# @timeout: 180
# @tags: usage, nodejs, crypto
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

node >"$tmpdir/out" <<'JS'
const assert = require('assert');
const crypto = require('crypto');

const { publicKey, privateKey } = crypto.generateKeyPairSync('ed25519');
assert.strictEqual(publicKey.asymmetricKeyType, 'ed25519');
assert.strictEqual(privateKey.asymmetricKeyType, 'ed25519');

const message = Buffer.from('ed25519 sign/verify payload\n');
const sig = crypto.sign(null, message, privateKey);
assert.strictEqual(sig.length, 64);

const ok = crypto.verify(null, message, publicKey, sig);
assert.strictEqual(ok, true, 'ed25519 verify must succeed');

const tampered = Buffer.from(message);
tampered[0] ^= 0x01;
const bad = crypto.verify(null, tampered, publicKey, sig);
assert.strictEqual(bad, false, 'tampered message must not verify');

console.log('OK ed25519', sig.length, ok, bad);
JS

validator_assert_contains "$tmpdir/out" 'OK ed25519 64 true false'
