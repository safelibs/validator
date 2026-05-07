#!/usr/bin/env bash
# @testcase: usage-nodejs-r13-crypto-hash-sha256-hex
# @title: Node.js crypto.createHash sha256 matches the published KAT digest for 'abc'
# @description: Computes sha256 of the string 'abc' via crypto.createHash and asserts the hex digest equals the well-known FIPS 180-4 KAT value ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad.
# @timeout: 60
# @tags: usage, crypto, hash, nodejs
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/script.js" <<'JS'
const assert = require('assert');
const crypto = require('crypto');
const digest = crypto.createHash('sha256').update('abc').digest('hex');
assert.strictEqual(digest, 'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad');
console.log('OK sha256.kat');
JS

node "$tmpdir/script.js" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'OK sha256.kat'
