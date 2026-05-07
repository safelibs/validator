#!/usr/bin/env bash
# @testcase: usage-nodejs-r12-net-tcp-loopback-port-zero
# @title: Node.js net.createServer + net.connect echo over an ephemeral 127.0.0.1 port
# @description: Listens on port 0 of 127.0.0.1, has the server echo bytes back, and asserts the client receives the same payload it sent.
# @timeout: 60
# @tags: usage, net, tcp, nodejs
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/script.js" <<'JS'
const assert = require('assert');
const net = require('net');

const server = net.createServer((s) => {
  s.on('data', (c) => s.write(c));
  s.on('end', () => s.end());
});
server.listen(0, '127.0.0.1', () => {
  const { port, address } = server.address();
  assert.strictEqual(address, '127.0.0.1');
  const client = net.createConnection(port, '127.0.0.1', () => {
    client.write('hello-r12');
    client.end();
  });
  const chunks = [];
  client.on('data', (c) => chunks.push(c));
  client.on('end', () => {
    const got = Buffer.concat(chunks).toString();
    assert.strictEqual(got, 'hello-r12');
    server.close();
    console.log('OK net.tcp.echo');
  });
  client.on('error', (e) => { throw e; });
});
JS

node "$tmpdir/script.js" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'OK net.tcp.echo'
