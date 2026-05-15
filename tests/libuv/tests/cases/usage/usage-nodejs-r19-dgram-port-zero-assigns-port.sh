#!/usr/bin/env bash
# @testcase: usage-nodejs-r19-dgram-port-zero-assigns-port
# @title: Node.js dgram.createSocket bind on port 0 returns a positive ephemeral port
# @description: Creates a udp4 dgram socket via dgram.createSocket, binds to address '127.0.0.1' on port 0, awaits the 'listening' event, calls socket.address() and asserts the returned object has port > 0, family is 'IPv4', and address is '127.0.0.1', closes the socket and asserts a 'close' callback fires, exercising libuv-backed UDP ephemeral-port assignment.
# @timeout: 60
# @tags: usage, nodejs, dgram, port-zero, r19
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
  assert.ok(addr.port > 0, 'port: ' + addr.port);
  assert.strictEqual(addr.family, 'IPv4');
  assert.strictEqual(addr.address, '127.0.0.1');
  sock.close(() => {
    console.log('OK dgram.port=' + addr.port);
  });
});
sock.on('error', (e) => { console.error(e); process.exit(1); });
JS

node "$tmpdir/script.js" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'OK dgram.port='
