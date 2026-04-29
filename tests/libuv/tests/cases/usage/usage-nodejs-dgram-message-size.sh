#!/usr/bin/env bash
# @testcase: usage-nodejs-dgram-message-size
# @title: Node.js dgram message size
# @description: Receives a UDP datagram over loopback and verifies the reported message length.
# @timeout: 180
# @tags: usage, nodejs, udp
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-nodejs-dgram-message-size"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

node >"$tmpdir/out" <<'JS'
const dgram = require('dgram');
const server = dgram.createSocket('udp4');
server.on('message', (message) => {
  console.log(message.length);
  server.close();
});
server.bind(0, '127.0.0.1', () => {
  const { port } = server.address();
  const client = dgram.createSocket('udp4');
  client.send(Buffer.from('payload'), port, '127.0.0.1', () => client.close());
});
JS
validator_assert_contains "$tmpdir/out" '7'
