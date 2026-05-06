#!/usr/bin/env bash
# @testcase: usage-nodejs-r11-util-callbackify-roundtrip
# @title: Node.js util.callbackify wraps an async function into node-style callback
# @description: Wraps an async function that doubles its argument with util.callbackify and asserts the resulting callback receives a null error and the doubled value.
# @timeout: 60
# @tags: usage, util, async, nodejs
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/script.js" <<'JS'
const assert = require('assert');
const util = require('util');
async function asyncDouble(n) { return n * 2; }
const cb = util.callbackify(asyncDouble);
cb(7, (err, val) => {
  assert.strictEqual(err, null);
  assert.strictEqual(val, 14);
  console.log('OK util.callbackify');
});
JS

node "$tmpdir/script.js" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'OK util.callbackify'
