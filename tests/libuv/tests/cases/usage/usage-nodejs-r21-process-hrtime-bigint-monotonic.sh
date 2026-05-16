#!/usr/bin/env bash
# @testcase: usage-nodejs-r21-process-hrtime-bigint-monotonic
# @title: Node.js process.hrtime.bigint reports a monotonically increasing nanosecond clock
# @description: Samples process.hrtime.bigint() twice across a 5 ms setTimeout delay and asserts the second sample is strictly greater than the first by at least 1 million nanoseconds (1 ms), exercising libuv's uv_hrtime backed monotonic clock.
# @timeout: 60
# @tags: usage, hrtime, nodejs, libuv, r21
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/s.js" <<'JS'
const assert = require('assert');

const a = process.hrtime.bigint();
setTimeout(() => {
  const b = process.hrtime.bigint();
  assert.ok(typeof a === 'bigint' && typeof b === 'bigint');
  const delta = b - a;
  assert.ok(delta > 1000000n, 'delta=' + delta.toString());
  console.log('OK hrtime delta_ns=' + delta.toString());
}, 5);
JS

node "$tmpdir/s.js" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'OK hrtime'
