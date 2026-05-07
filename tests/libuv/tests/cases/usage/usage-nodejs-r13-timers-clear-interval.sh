#!/usr/bin/env bash
# @testcase: usage-nodejs-r13-timers-clear-interval
# @title: Node.js setInterval fires repeatedly until clearInterval stops it
# @description: Schedules a 5 ms setInterval that increments a counter, calls clearInterval after the third tick, and asserts the counter stayed at exactly three after a longer wait.
# @timeout: 60
# @tags: usage, timers, nodejs
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/script.js" <<'JS'
const assert = require('assert');
let count = 0;
const handle = setInterval(() => {
  count += 1;
  if (count === 3) {
    clearInterval(handle);
    setTimeout(() => {
      assert.strictEqual(count, 3, 'count='+count);
      console.log('OK setInterval.clear');
    }, 30);
  }
}, 5);
JS

node "$tmpdir/script.js" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'OK setInterval.clear'
