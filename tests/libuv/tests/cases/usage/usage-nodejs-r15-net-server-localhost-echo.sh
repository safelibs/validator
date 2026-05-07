#!/usr/bin/env bash
# @testcase: usage-nodejs-r15-net-server-localhost-echo
# @title: Node.js net.Server on 127.0.0.1 echoes a payload back to the client
# @description: Starts a TCP server bound to 127.0.0.1 on port 0 that echoes received data, connects a client, sends a fixed payload, and asserts the client receives the same bytes back before close.
# @timeout: 60
# @tags: usage, net, nodejs
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/script.js" <<'JS'
const assert = require('assert');
const net = require('net');
const server = net.createServer((sock) => {
  sock.on('data', (chunk) => sock.write(chunk));
  sock.on('end', () => sock.end());
});
server.listen(0, '127.0.0.1', () => {
  const { port } = server.address();
  const client = net.connect(port, '127.0.0.1');
  let received = Buffer.alloc(0);
  client.on('data', (chunk) => { received = Buffer.concat([received, chunk]); });
  client.on('connect', () => {
    client.write('r15-net-echo');
    client.end();
  });
  client.on('end', () => {
    assert.strictEqual(received.toString('utf8'), 'r15-net-echo');
    server.close(() => console.log('OK net.echo'));
  });
});
JS

node "$tmpdir/script.js" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'OK net.echo'
