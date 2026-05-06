#!/usr/bin/env bash
# @testcase: usage-nodejs-r11-crypto-publickey-from-private-pem
# @title: Node.js crypto.createPublicKey extracts ed25519 public key from PKCS8 PEM private
# @description: Generates an ed25519 keypair, exports the private key as PKCS8 PEM, derives the public KeyObject from that PEM via createPublicKey, and asserts its SPKI export equals the original public PEM.
# @timeout: 60
# @tags: usage, crypto, ed25519, nodejs
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/script.js" <<'JS'
const assert = require('assert');
const crypto = require('crypto');
const { privateKey, publicKey } = crypto.generateKeyPairSync('ed25519');
const privatePem = privateKey.export({type: 'pkcs8', format: 'pem'});
const recovered = crypto.createPublicKey(privatePem);
assert.strictEqual(recovered.type, 'public');
assert.strictEqual(recovered.asymmetricKeyType, 'ed25519');
const origSpki = publicKey.export({type: 'spki', format: 'pem'});
const recSpki = recovered.export({type: 'spki', format: 'pem'});
assert.strictEqual(origSpki.toString(), recSpki.toString());
console.log('OK crypto.createPublicKey');
JS

node "$tmpdir/script.js" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'OK crypto.createPublicKey'
