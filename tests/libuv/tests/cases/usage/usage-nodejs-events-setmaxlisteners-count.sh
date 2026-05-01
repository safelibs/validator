#!/usr/bin/env bash
# @testcase: usage-nodejs-events-setmaxlisteners-count
# @title: Node.js EventEmitter setMaxListeners and listenerCount
# @description: Registers more than the default listeners after raising setMaxListeners and verifies listenerCount returns the registered total without warnings.
# @timeout: 120
# @tags: usage, events
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

node >"$tmpdir/out" 2>"$tmpdir/err" <<'JS'
const { EventEmitter } = require('events');
const ee = new EventEmitter();
ee.setMaxListeners(20);
for (let i = 0; i < 15; i++) ee.on('ping', () => {});
const n = ee.listenerCount('ping');
if (n !== 15) { console.error('count', n); process.exit(1); }
ee.removeAllListeners('ping');
if (ee.listenerCount('ping') !== 0) { console.error('not zero after removeAll'); process.exit(1); }
console.log('OK listeners 15 cleared');
JS

if grep -q 'MaxListenersExceededWarning' "$tmpdir/err"; then
  echo 'unexpected MaxListenersExceededWarning' >&2
  cat "$tmpdir/err" >&2
  exit 1
fi

validator_assert_contains "$tmpdir/out" 'OK listeners 15 cleared'
