#!/usr/bin/env bash
# @testcase: usage-nodejs-timers-promises-timeout-batch11
# @title: Node.js timers promises timeout
# @description: Awaits a timers/promises timeout through the Node.js event loop.
# @timeout: 180
# @tags: usage, nodejs, libuv
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-nodejs-timers-promises-timeout-batch11"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

node >"$tmpdir/out" <<'JS'
const timers = require('timers/promises');
(async () => {
  const value = await timers.setTimeout(10, 'timer-ok');
  console.log(value);
})().catch(err => { console.error(err); process.exit(1); });
JS
validator_assert_contains "$tmpdir/out" 'timer-ok'
