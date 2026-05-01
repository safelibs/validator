#!/usr/bin/env bash
# @testcase: usage-nodejs-net-socket-setkeepalive
# @title: Node.js net.Socket setKeepAlive on loopback connection
# @description: Calls socket.setKeepAlive(true, delay) on a client connected to a loopback server and verifies the connection completes a successful echo round-trip.
# @timeout: 180
# @tags: usage, event-loop, network
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

node >"$tmpdir/out" <<'JS'
const assert = require('assert');
const net = require('net');

const server = net.createServer((socket) => {
  socket.on('data', (chunk) => socket.end(chunk));
});
server.on('error', (e) => { console.error(e); process.exit(1); });

server.listen(0, '127.0.0.1', () => {
  const port = server.address().port;
  const client = net.createConnection({ port, host: '127.0.0.1' }, () => {
    const ok = client.setKeepAlive(true, 1000);
    assert.strictEqual(ok, client, 'setKeepAlive returns the socket');
    client.write('keepalive-payload');
  });
  let body = '';
  client.setEncoding('utf8');
  client.on('data', (chunk) => { body += chunk; });
  client.on('end', () => {
    server.close();
    assert.strictEqual(body, 'keepalive-payload');
    console.log('OK keepalive', body);
  });
  client.on('error', (e) => { console.error(e); process.exit(1); });
});
JS

validator_assert_contains "$tmpdir/out" 'OK keepalive keepalive-payload'
