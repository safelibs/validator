#!/usr/bin/env bash
# @testcase: usage-nodejs-r20-crypto-md5-abc-kat
# @title: Node.js crypto.createHash('md5') matches the published RFC 1321 KAT for "abc"
# @description: Calls crypto.createHash('md5').update('abc').digest('hex'), asserts the result equals the lowercase hex string '900150983cd24fb0d6963f7d28e17f72' (RFC 1321 test vector 'abc'), confirming Node's OpenSSL-backed MD5 implementation is correctly wired through the libuv-built runtime.
# @timeout: 60
# @tags: usage, nodejs, crypto, md5, kat, r20
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/script.js" <<'JS'
const assert = require('assert');
const crypto = require('crypto');
const h = crypto.createHash('md5').update('abc').digest('hex');
assert.strictEqual(h, '900150983cd24fb0d6963f7d28e17f72');
console.log('OK md5 ' + h);
JS

node "$tmpdir/script.js" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'OK md5 900150983cd24fb0d6963f7d28e17f72'
