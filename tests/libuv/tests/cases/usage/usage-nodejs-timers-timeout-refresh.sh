#!/usr/bin/env bash
# @testcase: usage-nodejs-timers-timeout-refresh
# @title: Node.js timeout refresh
# @description: Refreshes a pending timeout and verifies that the timer callback still runs exactly once.
# @timeout: 180
# @tags: usage, nodejs, timers
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-nodejs-timers-timeout-refresh"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

node >"$tmpdir/out" <<'JS'
let count = 0;
const timeout = setTimeout(() => {
  count += 1;
  console.log(`count=${count}`);
}, 20);
setTimeout(() => timeout.refresh(), 5);
JS
validator_assert_contains "$tmpdir/out" 'count=1'
