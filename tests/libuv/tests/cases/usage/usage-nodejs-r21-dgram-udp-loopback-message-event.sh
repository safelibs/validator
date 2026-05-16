#!/usr/bin/env bash
# @testcase: usage-nodejs-r21-dgram-udp-loopback-message-event
# @title: Node.js dgram UDP4 socket emits 'message' for an echoed loopback datagram
# @description: Creates a udp4 dgram.Socket, binds to 127.0.0.1 on a random port, sends a single datagram to its own address, listens for the 'message' event, and asserts the received payload equals the sent payload and rinfo.address is 127.0.0.1 over libuv's uv_udp facility.
# @timeout: 60
# @tags: usage, dgram, udp, loopback, nodejs, r21
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/s.js" <<'JS'
const assert = require('assert');
const dgram = require('dgram');

const sock = dgram.createSocket('udp4');
const payload = Buffer.from('r21 dgram loopback');

sock.on('message', (msg, rinfo) => {
  assert.deepStrictEqual(msg, payload, 'msg=' + msg.toString());
  assert.strictEqual(rinfo.address, '127.0.0.1', 'address=' + rinfo.address);
  sock.close(() => console.log('OK dgram bytes=' + msg.length));
});

sock.bind(0, '127.0.0.1', () => {
  const { port } = sock.address();
  sock.send(payload, port, '127.0.0.1');
});
JS

node "$tmpdir/s.js" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'OK dgram'
