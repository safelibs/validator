#!/usr/bin/env bash
# @testcase: usage-nodejs-r15-url-searchparams-get-set-roundtrip
# @title: Node.js URLSearchParams set then get returns the assigned value
# @description: Constructs new URLSearchParams('a=1&b=2'), sets 'a' to 'r15' and 'c' to 'three', and asserts get('a') returns 'r15', get('b') still returns '2', and get('c') returns 'three'.
# @timeout: 60
# @tags: usage, url, nodejs
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/script.js" <<'JS'
const assert = require('assert');
const params = new URLSearchParams('a=1&b=2');
params.set('a', 'r15');
params.set('c', 'three');
assert.strictEqual(params.get('a'), 'r15');
assert.strictEqual(params.get('b'), '2');
assert.strictEqual(params.get('c'), 'three');
console.log('OK URLSearchParams');
JS

node "$tmpdir/script.js" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'OK URLSearchParams'
