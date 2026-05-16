#!/usr/bin/env bash
# @testcase: usage-nodejs-r21-abort-controller-aborts-settimeout-promise
# @title: Node.js AbortController cancels a timers/promises setTimeout with AbortError
# @description: Schedules a timers/promises setTimeout(2000) with an AbortController signal, calls controller.abort() shortly after, awaits the promise and asserts it rejects with an AbortError, exercising libuv timer cancellation through Node's abort-aware timer API.
# @timeout: 60
# @tags: usage, timers, abort-controller, nodejs, r21
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/s.js" <<'JS'
const assert = require('assert');
const { setTimeout: sleep } = require('node:timers/promises');

(async () => {
  const ac = new AbortController();
  const p = sleep(2000, undefined, { signal: ac.signal });
  setTimeout(() => ac.abort(), 10);
  try {
    await p;
    throw new Error('expected AbortError');
  } catch (err) {
    assert.strictEqual(err.name, 'AbortError', 'err.name=' + err.name);
    console.log('OK aborted name=' + err.name);
  }
})();
JS

node "$tmpdir/s.js" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'OK aborted'
