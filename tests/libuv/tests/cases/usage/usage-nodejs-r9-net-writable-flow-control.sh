#!/usr/bin/env bash
# @testcase: usage-nodejs-r9-net-writable-flow-control
# @title: Node.js net socket write flow control
# @description: Streams 1 MiB of data through a 127.0.0.1 TCP echo connection and verifies the bytes received equal the bytes sent.
# @timeout: 60
# @tags: usage, net, nodejs
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

node - <<'JS'
const net = require('net');
const assert = require('assert');

const payload = Buffer.alloc(1024 * 1024, 0x41);
const server = net.createServer(s => { s.pipe(s); });
server.listen(0, '127.0.0.1', () => {
  const port = server.address().port;
  const client = net.connect(port, '127.0.0.1', () => {
    client.end(payload);
  });
  let received = 0;
  client.on('data', chunk => { received += chunk.length; });
  client.on('end', () => {
    assert.equal(received, payload.length);
    server.close();
  });
  client.on('error', e => { console.error(e); process.exit(1); });
});
JS
