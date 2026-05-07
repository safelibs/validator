#!/usr/bin/env bash
# @testcase: usage-nodejs-r14-util-types-is-promise
# @title: Node.js util.types.isPromise distinguishes native promises from plain objects
# @description: Asserts util.types.isPromise returns true for Promise.resolve() and an async-function call, and returns false for plain objects, thenables, and primitive values.
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
assert.strictEqual(util.types.isPromise(Promise.resolve(1)), true);
assert.strictEqual(util.types.isPromise((async () => 1)()), true);
assert.strictEqual(util.types.isPromise({}), false);
assert.strictEqual(util.types.isPromise({ then: () => {} }), false);
assert.strictEqual(util.types.isPromise(null), false);
assert.strictEqual(util.types.isPromise('promise'), false);
console.log('OK util.types.isPromise');
JS

node "$tmpdir/script.js" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'OK util.types.isPromise'
