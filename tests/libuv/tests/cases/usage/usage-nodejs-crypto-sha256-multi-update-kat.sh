#!/usr/bin/env bash
# @testcase: usage-nodejs-crypto-sha256-multi-update-kat
# @title: Node.js crypto sha256 multi-update KAT
# @description: Builds a sha256 digest with multiple update calls and verifies it against the published KAT for the concatenated input.
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

// sha256("abc") = ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad
const expected = 'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad';

const h = crypto.createHash('sha256');
h.update('a');
h.update(Buffer.from('b'));
h.update('c', 'utf8');
const digest = h.digest('hex');
assert.strictEqual(digest, expected);

// Sanity: same digest in one shot.
const oneShot = crypto.createHash('sha256').update('abc').digest('hex');
assert.strictEqual(oneShot, expected);

console.log('OK sha256', digest);
JS

validator_assert_contains "$tmpdir/out" "OK sha256 ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"
