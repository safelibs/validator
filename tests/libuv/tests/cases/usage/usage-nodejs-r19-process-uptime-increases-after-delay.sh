#!/usr/bin/env bash
# @testcase: usage-nodejs-r19-process-uptime-increases-after-delay
# @title: Node.js process.uptime increases after a libuv timer-backed delay
# @description: Captures process.uptime() into t0, awaits a setTimeout of 30ms via timers/promises, captures process.uptime() into t1, and asserts t1 > t0 and (t1 - t0) >= 0.015 seconds (15ms, allowing scheduler slack against the 30ms target), confirming process.uptime advances monotonically over libuv-driven timer intervals.
# @timeout: 60
# @tags: usage, nodejs, process, uptime, timers, r19
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/script.js" <<'JS'
const assert = require('assert');
const { setTimeout: stp } = require('timers/promises');
(async () => {
  const t0 = process.uptime();
  await stp(30);
  const t1 = process.uptime();
  assert.ok(t1 > t0, 't1<=t0: ' + t0 + ' vs ' + t1);
  const dt = t1 - t0;
  assert.ok(dt >= 0.015, 'dt too small: ' + dt);
  console.log('OK uptime.dt=' + dt.toFixed(3));
})().catch((e) => { console.error(e); process.exit(1); });
JS

node "$tmpdir/script.js" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'OK uptime.dt='
