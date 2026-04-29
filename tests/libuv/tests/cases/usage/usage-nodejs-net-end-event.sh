#!/usr/bin/env bash
# @testcase: usage-nodejs-net-end-event
# @title: Node.js net end event
# @description: Exchanges data over a loopback TCP socket and verifies the client end event payload.
# @timeout: 180
# @tags: usage, nodejs, net
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-nodejs-net-end-event"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

node >"$tmpdir/out" <<'JS'
const net = require('net');
const server = net.createServer((socket) => {
  socket.end('done');
});
server.listen(0, '127.0.0.1', () => {
  const { port } = server.address();
  const client = net.createConnection({ port, host: '127.0.0.1' });
  let data = '';
  client.on('data', (chunk) => { data += chunk.toString('utf8'); });
  client.on('end', () => {
    console.log(data);
    server.close();
  });
});
JS
validator_assert_contains "$tmpdir/out" 'done'
