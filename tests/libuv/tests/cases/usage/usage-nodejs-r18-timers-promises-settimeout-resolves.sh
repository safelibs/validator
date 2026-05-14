#!/usr/bin/env bash
# @testcase: usage-nodejs-r18-timers-promises-settimeout-resolves
# @title: Node.js timers/promises setTimeout resolves with the supplied value after a delay
# @description: Calls require('timers/promises').setTimeout(20, 'r18-token') and awaits the promise, asserts the resolved value equals "r18-token", and asserts that the measured elapsed milliseconds (Date.now diff) is at least 15 (allowing scheduler slack), exercising libuv-backed timer scheduling via the promise-based timers API.
# @timeout: 60
# @tags: usage, nodejs, timers, promises, r18
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/script.js" <<'JS'
const assert = require('assert');
const { setTimeout: stp } = require('timers/promises');
(async () => {
  const t0 = Date.now();
  const v = await stp(20, 'r18-token');
  const dt = Date.now() - t0;
  assert.strictEqual(v, 'r18-token');
  assert.ok(dt >= 15, 'dt too small: ' + dt);
  console.log('OK setTimeout.value=' + v);
})().catch((e) => { console.error(e); process.exit(1); });
JS

node "$tmpdir/script.js" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'OK setTimeout.value=r18-token'
