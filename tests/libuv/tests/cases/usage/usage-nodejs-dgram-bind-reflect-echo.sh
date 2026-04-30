#!/usr/bin/env bash
# @testcase: usage-nodejs-dgram-bind-reflect-echo
# @title: Node.js dgram bind ephemeral and reflect
# @description: Binds a UDP4 socket to an ephemeral port on 127.0.0.1, reflects a datagram back to the sender, and verifies the round trip.
# @timeout: 180
# @tags: usage, event-loop, network, dgram
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

node >"$tmpdir/out" <<'JS'
const assert = require('assert');
const dgram = require('dgram');

const reflector = dgram.createSocket('udp4');
const client = dgram.createSocket('udp4');

reflector.on('message', (msg, rinfo) => {
  // Reflect the payload prefixed with marker back to the originating address/port.
  const reply = Buffer.concat([Buffer.from('echo:'), msg]);
  reflector.send(reply, rinfo.port, rinfo.address);
});
reflector.on('error', (e) => { throw e; });
client.on('error', (e) => { throw e; });

client.on('message', (msg) => {
  assert.strictEqual(msg.toString('utf8'), 'echo:reflect-me');
  client.close();
  reflector.close();
  console.log('OK reflect', msg.toString('utf8'));
});

reflector.bind(0, '127.0.0.1', () => {
  const addr = reflector.address();
  assert.strictEqual(addr.address, '127.0.0.1');
  assert.ok(addr.port > 0);
  client.bind(0, '127.0.0.1', () => {
    client.send(Buffer.from('reflect-me'), addr.port, '127.0.0.1');
  });
});
JS

validator_assert_contains "$tmpdir/out" 'OK reflect echo:reflect-me'
