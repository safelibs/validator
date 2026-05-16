#!/usr/bin/env bash
# @testcase: usage-nodejs-r21-net-server-localaddress-loopback
# @title: Node.js connected client socket reports localAddress 127.0.0.1
# @description: Starts a net.Server listening on 127.0.0.1 with an ephemeral port, has a client connect over loopback, and asserts inside the 'connection' handler that the accepted socket.remoteAddress is 127.0.0.1 and that the client socket.localAddress is also 127.0.0.1 over the libuv-backed TCP path.
# @timeout: 60
# @tags: usage, net, loopback, nodejs, r21
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/s.js" <<'JS'
const assert = require('assert');
const net = require('net');

const server = net.createServer((sock) => {
  assert.strictEqual(sock.remoteAddress, '127.0.0.1', 'remote=' + sock.remoteAddress);
  sock.end();
});

server.listen(0, '127.0.0.1', () => {
  const { port } = server.address();
  const client = net.createConnection({ host: '127.0.0.1', port }, () => {
    assert.strictEqual(client.localAddress, '127.0.0.1', 'local=' + client.localAddress);
    client.on('end', () => {
      server.close(() => console.log('OK localAddress=127.0.0.1'));
    });
  });
});
JS

node "$tmpdir/s.js" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'OK localAddress=127.0.0.1'
