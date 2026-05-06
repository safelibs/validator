#!/usr/bin/env bash
# @testcase: usage-nodejs-r11-dgram-setbroadcast-buffer-sizes
# @title: Node.js dgram setBroadcast returns positive recv and send buffer sizes
# @description: Binds a UDP4 socket on a random loopback port, calls setBroadcast(true), then verifies getRecvBufferSize and getSendBufferSize both report kernel-positive values.
# @timeout: 60
# @tags: usage, dgram, nodejs
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/script.js" <<'JS'
const assert = require('assert');
const dgram = require('dgram');
const sock = dgram.createSocket('udp4');
sock.bind(0, '127.0.0.1', () => {
  sock.setBroadcast(true);
  const recvSz = sock.getRecvBufferSize();
  const sendSz = sock.getSendBufferSize();
  assert.ok(recvSz > 0, 'recv buffer size should be > 0, got ' + recvSz);
  assert.ok(sendSz > 0, 'send buffer size should be > 0, got ' + sendSz);
  sock.close(() => console.log('OK dgram.broadcast'));
});
JS

node "$tmpdir/script.js" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'OK dgram.broadcast'
