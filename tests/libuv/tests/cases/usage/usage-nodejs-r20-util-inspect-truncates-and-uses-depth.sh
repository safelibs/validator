#!/usr/bin/env bash
# @testcase: usage-nodejs-r20-util-inspect-truncates-and-uses-depth
# @title: Node.js util.inspect respects depth option and stops at the configured nesting level
# @description: Calls util.inspect({a: {b: {c: 1}}}, { depth: 0 }) and asserts the returned string contains the substring '[Object]' (indicating depth truncation kicked in), then calls util.inspect with depth: 5 on the same object and asserts the output contains 'c: 1' (full nesting visible), confirming Node's documented inspect depth-bound semantics.
# @timeout: 60
# @tags: usage, nodejs, util, inspect, depth, r20
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/script.js" <<'JS'
const assert = require('assert');
const util = require('util');
const obj = { a: { b: { c: 1 } } };
const shallow = util.inspect(obj, { depth: 0 });
assert.ok(shallow.includes('[Object]'), 'shallow=' + shallow);
const deep = util.inspect(obj, { depth: 5 });
assert.ok(deep.includes('c: 1'), 'deep=' + deep);
console.log('OK util.inspect');
JS

node "$tmpdir/script.js" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'OK util.inspect'
