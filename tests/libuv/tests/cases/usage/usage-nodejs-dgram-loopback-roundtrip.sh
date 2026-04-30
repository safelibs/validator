#!/usr/bin/env bash
# @testcase: usage-nodejs-dgram-loopback-roundtrip
# @title: Node.js dgram UDP loopback round-trip
# @description: Sends a UDP datagram to a loopback server which replies, and asserts the client receives the reply payload.
# @timeout: 180
# @tags: usage, event-loop, network
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

node >"$tmpdir/out" <<'JS'
const assert = require('assert');
const dgram = require('dgram');

const server = dgram.createSocket('udp4');
const client = dgram.createSocket('udp4');

server.on('message', (msg, rinfo) => {
  assert.strictEqual(msg.toString(), 'ping-payload');
  server.send(Buffer.from('pong-payload'), rinfo.port, rinfo.address);
});

client.on('message', (msg) => {
  assert.strictEqual(msg.toString(), 'pong-payload');
  client.close();
  server.close();
  console.log('OK roundtrip', msg.toString());
});

server.bind(0, '127.0.0.1', () => {
  const port = server.address().port;
  client.bind(0, '127.0.0.1', () => {
    client.send(Buffer.from('ping-payload'), port, '127.0.0.1', (err) => {
      if (err) throw err;
    });
  });
});
JS

validator_assert_contains "$tmpdir/out" 'OK roundtrip pong-payload'
