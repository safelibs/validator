#!/usr/bin/env bash
# @testcase: usage-nodejs-dgram-buffer-message-batch11
# @title: Node.js dgram buffer message
# @description: Sends a UDP datagram Buffer between Node.js sockets.
# @timeout: 180
# @tags: usage, nodejs, libuv
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-nodejs-dgram-buffer-message-batch11"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

node >"$tmpdir/out" <<'JS'
const dgram = require('dgram');
const server = dgram.createSocket('udp4');
server.on('message', msg => { console.log(msg.toString()); server.close(); });
server.bind(0, '127.0.0.1', () => {
  const client = dgram.createSocket('udp4');
  const port = server.address().port;
  client.send(Buffer.from('udp-buffer-ok'), port, '127.0.0.1', () => client.close());
});
JS
validator_assert_contains "$tmpdir/out" 'udp-buffer-ok'
