#!/usr/bin/env bash
# @testcase: usage-nodejs-r11-querystring-parse-multi-value
# @title: Node.js querystring.parse aggregates repeated keys into arrays
# @description: Parses a query string with two repeated color= entries plus a singleton size= and asserts color is an ordered string array while size remains a scalar string.
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
const parsed = qs.parse('color=red&color=blue&size=L');
assert.deepStrictEqual(parsed.color, ['red', 'blue']);
assert.strictEqual(parsed.size, 'L');
const single = qs.parse('q=hello%20world&n=5');
assert.strictEqual(single.q, 'hello world');
assert.strictEqual(single.n, '5');
console.log('OK querystring.parse');
JS

node "$tmpdir/script.js" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'OK querystring.parse'
