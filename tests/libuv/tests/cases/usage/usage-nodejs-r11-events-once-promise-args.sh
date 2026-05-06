#!/usr/bin/env bash
# @testcase: usage-nodejs-r11-events-once-promise-args
# @title: Node.js events.once awaits next emit and resolves with full argument tuple
# @description: Schedules a deferred emit of a two-argument ready event and asserts the events.once Promise resolves to an ordered array with both arguments.
# @timeout: 60
# @tags: usage, events, async, nodejs
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/script.js" <<'JS'
const assert = require('assert');
const events = require('node:events');
const { EventEmitter } = events;
const ee = new EventEmitter();
(async () => {
  setImmediate(() => ee.emit('ready', 'arg1', 'arg2'));
  const args = await events.once(ee, 'ready');
  assert.deepStrictEqual(args, ['arg1', 'arg2']);
  console.log('OK events.once');
})().catch((err) => { console.error(err); process.exit(1); });
JS

node "$tmpdir/script.js" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'OK events.once'
