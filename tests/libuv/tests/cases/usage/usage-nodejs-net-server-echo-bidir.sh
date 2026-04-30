#!/usr/bin/env bash
# @testcase: usage-nodejs-net-server-echo-bidir
# @title: Node.js net loopback echo with sha256 verification
# @description: Binds a TCP server on 127.0.0.1, echoes a 16 KiB payload back to a client, and verifies sha256 equality.
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
const crypto = require('crypto');

const payload = crypto.randomBytes(16 * 1024);
const expected = crypto.createHash('sha256').update(payload).digest('hex');

const server = net.createServer((sock) => {
  sock.on('data', (chunk) => sock.write(chunk));
  sock.on('end', () => sock.end());
});

server.listen(0, '127.0.0.1', () => {
  const { port, address } = server.address();
  assert.strictEqual(address, '127.0.0.1');
  const client = net.createConnection({ port, host: '127.0.0.1' }, () => {
    client.write(payload);
    client.end();
  });
  const chunks = [];
  client.on('data', (c) => chunks.push(c));
  client.on('end', () => {
    server.close();
    const got = Buffer.concat(chunks);
    assert.strictEqual(got.length, payload.length);
    const gotHash = crypto.createHash('sha256').update(got).digest('hex');
    assert.strictEqual(gotHash, expected);
    console.log('OK echo', got.length, gotHash.slice(0, 12));
  });
  client.on('error', (e) => { throw e; });
});
server.on('error', (e) => { throw e; });
JS

validator_assert_contains "$tmpdir/out" 'OK echo 16384'
