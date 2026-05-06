#!/usr/bin/env bash
# @testcase: usage-nodejs-r11-broadcastchannel-cross-channel
# @title: Node.js BroadcastChannel delivers postMessage between same-named channels
# @description: Opens two BroadcastChannel instances with the same name, posts a string from one, and asserts the other receives it via the onmessage handler.
# @timeout: 60
# @tags: usage, worker_threads, broadcastchannel, nodejs
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/script.js" <<'JS'
const assert = require('assert');
const { BroadcastChannel } = require('node:worker_threads');
const ch1 = new BroadcastChannel('channel-r11-test');
const ch2 = new BroadcastChannel('channel-r11-test');
ch2.onmessage = (event) => {
  assert.strictEqual(event.data, 'hello-r11');
  ch1.close();
  ch2.close();
  console.log('OK broadcastchannel');
};
ch1.postMessage('hello-r11');
JS

node "$tmpdir/script.js" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'OK broadcastchannel'
