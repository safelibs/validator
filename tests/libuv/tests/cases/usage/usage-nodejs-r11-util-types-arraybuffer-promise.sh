#!/usr/bin/env bash
# @testcase: usage-nodejs-r11-util-types-arraybuffer-promise
# @title: Node.js util.types discriminates ArrayBuffer, Promise, and AsyncFunction
# @description: Calls util.types.isArrayBuffer, isPromise, and isAsyncFunction with positive and negative samples and asserts each predicate returns true only for the matching primitive.
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
assert.strictEqual(util.types.isArrayBuffer(new ArrayBuffer(8)), true);
assert.strictEqual(util.types.isArrayBuffer(Buffer.alloc(8)), false);
assert.strictEqual(util.types.isPromise(Promise.resolve()), true);
assert.strictEqual(util.types.isPromise({then: () => {}}), false);
assert.strictEqual(util.types.isAsyncFunction(async () => {}), true);
assert.strictEqual(util.types.isAsyncFunction(() => {}), false);
console.log('OK util.types');
JS

node "$tmpdir/script.js" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'OK util.types'
