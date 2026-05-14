#!/usr/bin/env bash
# @testcase: usage-nodejs-r18-net-server-loopback-echo-roundtrip
# @title: Node.js net.createServer echoes data back over a loopback TCP socket
# @description: Starts a net.createServer that echoes every chunk received back to the client, binds on 127.0.0.1 with an OS-assigned port, calls net.createConnection to the bound port, writes a fixed payload, and asserts the data event on the client delivers the same payload back byte-for-byte before both sides are closed, exercising libuv-backed TCP I/O on loopback.
# @timeout: 60
# @tags: usage, nodejs, net, tcp, loopback, r18
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/script.js" <<'JS'
const assert = require('assert');
const net = require('net');

const payload = Buffer.from('r18 nodejs net loopback echo payload', 'utf8');

const server = net.createServer((socket) => {
  socket.on('data', (chunk) => { socket.write(chunk); });
  socket.on('end', () => socket.end());
});

server.listen(0, '127.0.0.1', () => {
  const port = server.address().port;
  const chunks = [];
  const client = net.createConnection({ host: '127.0.0.1', port }, () => {
    client.write(payload);
  });
  client.on('data', (d) => {
    chunks.push(d);
    if (Buffer.concat(chunks).length >= payload.length) {
      client.end();
    }
  });
  client.on('end', () => {
    const got = Buffer.concat(chunks);
    assert.deepStrictEqual(got, payload);
    server.close(() => {
      console.log('OK echo.len=' + got.length);
    });
  });
  client.on('error', (e) => { console.error(e); process.exit(1); });
});

server.on('error', (e) => { console.error(e); process.exit(1); });
JS

node "$tmpdir/script.js" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'OK echo.len='
