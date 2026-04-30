#!/usr/bin/env bash
# @testcase: usage-nodejs-dgram-socket-address-family
# @title: Node.js dgram socket.address family and ephemeral port
# @description: Binds a udp4 dgram socket to port 0 on loopback and verifies socket.address() returns family IPv4, address 127.0.0.1, and a positive ephemeral port.
# @timeout: 180
# @tags: usage, nodejs, network
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

node >"$tmpdir/out" <<'JS'
const assert = require('assert');
const dgram = require('dgram');

(async () => {
  const socket = dgram.createSocket('udp4');
  await new Promise((resolve, reject) => {
    socket.once('error', reject);
    socket.bind(0, '127.0.0.1', resolve);
  });

  const addr = socket.address();
  assert.strictEqual(addr.address, '127.0.0.1');
  assert.strictEqual(addr.family, 'IPv4');
  assert.ok(Number.isInteger(addr.port), 'port must be integer');
  assert.ok(addr.port > 0 && addr.port < 65536, `unexpected port ${addr.port}`);

  await new Promise((resolve) => socket.close(resolve));
  console.log('OK dgram-address', addr.family, addr.address, addr.port > 0 ? 'ephemeral' : 'fixed');
})().catch((err) => {
  console.error(err && err.stack || err);
  process.exit(1);
});
JS

validator_assert_contains "$tmpdir/out" 'OK dgram-address IPv4 127.0.0.1 ephemeral'
