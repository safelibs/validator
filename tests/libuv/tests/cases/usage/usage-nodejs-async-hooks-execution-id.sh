#!/usr/bin/env bash
# @testcase: usage-nodejs-async-hooks-execution-id
# @title: Node.js async_hooks executionAsyncId in setImmediate callback
# @description: Reads async_hooks.executionAsyncId at the top level and inside a setImmediate callback and asserts they are non-negative integers and differ.
# @timeout: 180
# @tags: usage, event-loop, async-hooks
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

node >"$tmpdir/out" <<'JS'
const assert = require('assert');
const async_hooks = require('async_hooks');

const topId = async_hooks.executionAsyncId();
assert.strictEqual(typeof topId, 'number');
assert.ok(Number.isInteger(topId));
assert.ok(topId >= 0, 'top async id non-negative');

setImmediate(() => {
  const innerId = async_hooks.executionAsyncId();
  assert.strictEqual(typeof innerId, 'number');
  assert.ok(Number.isInteger(innerId));
  assert.ok(innerId >= 0, 'inner async id non-negative');
  assert.notStrictEqual(innerId, topId, 'inner id differs from top');
  console.log('OK async-hooks differ');
});
JS

validator_assert_contains "$tmpdir/out" 'OK async-hooks differ'
