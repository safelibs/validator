#!/usr/bin/env bash
# @testcase: usage-nodejs-r14-querystring-stringify-roundtrip
# @title: Node.js querystring.stringify and parse round-trip a multi-key object
# @description: Calls querystring.stringify on an object with mixed string and number values, asserts the encoded form contains the expected key=value pairs joined by ampersands, and parses the result back asserting numeric values come back as their string representation.
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
const encoded = qs.stringify({ name: 'alice', age: 30, city: 'paris' });
// querystring.stringify preserves insertion order.
assert.strictEqual(encoded, 'name=alice&age=30&city=paris');
const parsed = qs.parse(encoded);
assert.strictEqual(parsed.name, 'alice');
assert.strictEqual(parsed.age, '30');
assert.strictEqual(parsed.city, 'paris');
// Spaces are %-encoded.
const sp = qs.stringify({ q: 'two words' });
assert.strictEqual(sp, 'q=two%20words');
console.log('OK querystring.stringify');
JS

node "$tmpdir/script.js" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'OK querystring.stringify'
