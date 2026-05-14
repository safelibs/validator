#!/usr/bin/env bash
# @testcase: usage-nodejs-r17-json-stringify-key-order-stable
# @title: Node.js JSON.stringify preserves declaration order for a small literal object
# @description: Serializes the literal {a:1, b:2, c:3} with JSON.stringify, asserts the output is exactly the string '{"a":1,"b":2,"c":3}' (no whitespace, declaration order preserved), and asserts JSON.parse round-trips it back to a deep-equal object.
# @timeout: 60
# @tags: usage, nodejs, json, r17
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/script.js" <<'JS'
const assert = require('assert');
const obj = { a: 1, b: 2, c: 3 };
const s = JSON.stringify(obj);
assert.strictEqual(s, '{"a":1,"b":2,"c":3}');
assert.deepStrictEqual(JSON.parse(s), obj);
console.log('OK json=' + s);
JS

node "$tmpdir/script.js" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'OK json={"a":1,"b":2,"c":3}'
