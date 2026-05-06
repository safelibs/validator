#!/usr/bin/env bash
# @testcase: usage-nodejs-r10-net-unix-socket-roundtrip
# @title: Node.js net loopback over a Unix domain socket
# @description: Binds a net.Server on a filesystem Unix domain socket, sends a 4 KiB payload from a client, and verifies the bytes echo back unchanged via sha256 equality.
# @timeout: 60
# @tags: usage, net, unix, nodejs
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

node - "$tmpdir/sock" <<'JS'
const assert = require('assert');
const net = require('net');
const crypto = require('crypto');

const sockPath = process.argv[2];
const payload = crypto.randomBytes(4096);
const expected = crypto.createHash('sha256').update(payload).digest('hex');

const server = net.createServer((s) => {
  s.on('data', (c) => s.write(c));
  s.on('end', () => s.end());
});

server.listen(sockPath, () => {
  const client = net.createConnection(sockPath, () => {
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
  });
  client.on('error', (e) => { throw e; });
});
server.on('error', (e) => { throw e; });
JS
