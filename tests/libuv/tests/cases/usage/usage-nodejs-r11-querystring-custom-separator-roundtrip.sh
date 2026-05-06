#!/usr/bin/env bash
# @testcase: usage-nodejs-r11-querystring-custom-separator-roundtrip
# @title: Node.js querystring stringify and parse round-trip with custom separator and equals
# @description: Stringifies an object using semicolon separator and tilde assignment, asserts the encoded shape, then re-parses to the original key/value pairs.
# @timeout: 60
# @tags: usage, querystring, nodejs
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/script.js" <<'JS'
const assert = require('assert');
const qs = require('querystring');
const out = qs.stringify({a: 1, b: 'x y'}, ';', '~');
assert.strictEqual(out, 'a~1;b~x%20y');
const back = qs.parse(out, ';', '~');
assert.strictEqual(back.a, '1');
assert.strictEqual(back.b, 'x y');
console.log('OK querystring.roundtrip');
JS

node "$tmpdir/script.js" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'OK querystring.roundtrip'
