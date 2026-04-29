#!/usr/bin/env bash
# @testcase: usage-nodejs-timers-promises-immediate
# @title: Node.js timers promises immediate
# @description: Awaits timers/promises.setImmediate in Node.js and verifies the resolved payload value.
# @timeout: 180
# @tags: usage, nodejs, timers
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-nodejs-timers-promises-immediate"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

node >"$tmpdir/out" <<'JS'
const timersPromises = require('timers/promises');
(async () => {
  const value = await timersPromises.setImmediate('immediate done');
  console.log(value);
})();
JS
validator_assert_contains "$tmpdir/out" 'immediate done'
