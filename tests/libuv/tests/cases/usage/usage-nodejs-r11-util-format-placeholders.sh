#!/usr/bin/env bash
# @testcase: usage-nodejs-r11-util-format-placeholders
# @title: Node.js util.format substitutes %s %d %j placeholders
# @description: Builds a formatted string with %s, %d, and %j placeholders against a string, integer, and JSON-serializable object and asserts the result matches the expected concatenation byte-for-byte.
# @timeout: 60
# @tags: usage, util, nodejs
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/script.js" <<'JS'
const assert = require('assert');
const util = require('util');
const out = util.format('name=%s count=%d obj=%j', 'foo', 42, {a: 1});
assert.strictEqual(out, 'name=foo count=42 obj={"a":1}');
const seq = util.format('%s%s%s', 'a', 'b', 'c');
assert.strictEqual(seq, 'abc');
console.log('OK util.format');
JS

node "$tmpdir/script.js" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'OK util.format'
