#!/usr/bin/env bash
# @testcase: usage-nodejs-r12-dgram-udp4-port-zero
# @title: Node.js dgram udp4 binds an ephemeral port and exposes 127.0.0.1 address
# @description: Creates a udp4 socket bound to port 0 on 127.0.0.1 and asserts socket.address() reports the loopback address with a non-zero allocated port.
# @timeout: 60
# @tags: usage, dgram, udp4, nodejs
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
  const addr = sock.address();
  assert.strictEqual(addr.address, '127.0.0.1');
  assert.strictEqual(addr.family, 'IPv4');
  assert.ok(typeof addr.port === 'number' && addr.port > 0, 'port='+addr.port);
  sock.close(() => console.log('OK dgram.udp4.bind'));
});
JS

node "$tmpdir/script.js" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'OK dgram.udp4.bind'
