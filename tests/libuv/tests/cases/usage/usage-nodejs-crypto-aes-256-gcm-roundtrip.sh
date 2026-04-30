#!/usr/bin/env bash
# @testcase: usage-nodejs-crypto-aes-256-gcm-roundtrip
# @title: Node.js crypto aes-256-gcm encrypt/decrypt round-trip
# @description: Encrypts a payload with crypto.createCipheriv aes-256-gcm, captures the auth tag, decrypts with createDecipheriv and the tag, and asserts the recovered plaintext matches.
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

const key = crypto.randomBytes(32);
const iv = crypto.randomBytes(12);
const aad = Buffer.from('header-v1');
const plaintext = Buffer.from('aes-gcm round-trip payload\n');

const cipher = crypto.createCipheriv('aes-256-gcm', key, iv);
cipher.setAAD(aad);
const ct = Buffer.concat([cipher.update(plaintext), cipher.final()]);
const tag = cipher.getAuthTag();
assert.strictEqual(tag.length, 16);
assert.notStrictEqual(ct.toString('hex'), plaintext.toString('hex'));

const decipher = crypto.createDecipheriv('aes-256-gcm', key, iv);
decipher.setAAD(aad);
decipher.setAuthTag(tag);
const recovered = Buffer.concat([decipher.update(ct), decipher.final()]);
assert.ok(recovered.equals(plaintext), 'plaintext mismatch');

// Tampered ciphertext must throw on final().
const tampered = Buffer.from(ct);
tampered[0] ^= 0x01;
const bad = crypto.createDecipheriv('aes-256-gcm', key, iv);
bad.setAAD(aad);
bad.setAuthTag(tag);
let threw = false;
try { bad.update(tampered); bad.final(); } catch (_) { threw = true; }
assert.ok(threw, 'tampered ciphertext must fail auth');

console.log('OK aes-gcm', plaintext.length, ct.length, tag.length);
JS

validator_assert_contains "$tmpdir/out" 'OK aes-gcm 27 27 16'
