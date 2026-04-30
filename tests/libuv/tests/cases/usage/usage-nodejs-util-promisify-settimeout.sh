#!/usr/bin/env bash
# @testcase: usage-nodejs-util-promisify-settimeout
# @title: Node.js util.promisify on setTimeout
# @description: Promisifies the legacy setTimeout signature and awaits a 25ms delay, asserting it resolves with no value and that elapsed time is non-negative.
# @timeout: 180
# @tags: usage, event-loop, util, timers
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

node >"$tmpdir/out" <<'JS'
const assert = require('assert');
const util = require('util');

(async () => {
  const sleep = util.promisify((ms, cb) => setTimeout(() => cb(null), ms));
  const start = process.hrtime.bigint();
  const result = await sleep(25);
  const elapsedMs = Number(process.hrtime.bigint() - start) / 1e6;

  assert.strictEqual(result, undefined);
  assert.ok(elapsedMs >= 0, 'elapsedMs >= 0');
  assert.ok(Number.isFinite(elapsedMs));

  console.log('OK promisify settimeout');
})().catch((e) => { console.error(e); process.exit(1); });
JS

validator_assert_contains "$tmpdir/out" 'OK promisify settimeout'
