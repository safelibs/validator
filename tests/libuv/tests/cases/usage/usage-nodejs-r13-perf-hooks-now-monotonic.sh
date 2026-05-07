#!/usr/bin/env bash
# @testcase: usage-nodejs-r13-perf-hooks-now-monotonic
# @title: Node.js perf_hooks.performance.now is monotonic across a setTimeout delay
# @description: Captures performance.now before and after a 25 ms setTimeout, asserts the second sample is strictly greater than the first, and that the elapsed delta is at least 20 ms.
# @timeout: 60
# @tags: usage, perf-hooks, nodejs
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/script.js" <<'JS'
const assert = require('assert');
const { performance } = require('perf_hooks');
const t0 = performance.now();
setTimeout(() => {
  const t1 = performance.now();
  assert.ok(t1 > t0, `t1=${t1} t0=${t0}`);
  const delta = t1 - t0;
  assert.ok(delta >= 20, `delta=${delta}`);
  console.log('OK performance.now');
}, 25);
JS

node "$tmpdir/script.js" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'OK performance.now'
