#!/usr/bin/env bash
# @testcase: usage-nodejs-r21-async-hooks-create-hook-fires-init
# @title: Node.js async_hooks createHook init callback fires for setTimeout async resources
# @description: Creates a node:async_hooks hook with an init callback that records async resource types, enables the hook, schedules a setTimeout, and after the timer fires asserts that 'Timeout' appears in the recorded types, exercising libuv's async resource lifecycle reporting via Node async_hooks.
# @timeout: 60
# @tags: usage, async-hooks, nodejs, r21
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/s.js" <<'JS'
const assert = require('assert');
const async_hooks = require('node:async_hooks');

const seen = new Set();
const hook = async_hooks.createHook({
  init(asyncId, type) { seen.add(type); },
});
hook.enable();

setTimeout(() => {
  hook.disable();
  assert.ok(seen.has('Timeout'), 'types=' + [...seen].join(','));
  console.log('OK async-hooks types=' + seen.size);
}, 10);
JS

node "$tmpdir/s.js" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'OK async-hooks'
