#!/usr/bin/env bash
# @testcase: usage-nodejs-r17-crypto-sha256-abc-kat
# @title: Node.js crypto.createHash('sha256').update('abc') matches the FIPS-180 KAT
# @description: Computes SHA-256 of the ASCII string "abc" via crypto.createHash, asserts the lowercase hex digest equals the FIPS-180-2 known answer "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad", and asserts the digest length is exactly 64 hex characters.
# @timeout: 60
# @tags: usage, nodejs, crypto, sha256, kat, r17
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/script.js" <<'JS'
const assert = require('assert');
const crypto = require('crypto');
const digest = crypto.createHash('sha256').update('abc').digest('hex');
assert.strictEqual(digest.length, 64);
assert.strictEqual(digest, 'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad');
console.log('OK sha256.abc=' + digest);
JS

node "$tmpdir/script.js" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'OK sha256.abc=ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad'
