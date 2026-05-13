#!/usr/bin/env bash
# @testcase: usage-nodejs-r16-net-server-accept-loopback-connection
# @title: Node.js net.createServer accepts a single loopback TCP connection event
# @description: Creates a TCP server bound to 127.0.0.1:0 that records 'connection' events, opens a single client connection, ends it cleanly, and asserts the server observed exactly one connection event with a remoteAddress in the IPv4 loopback range before close.
# @timeout: 60
# @tags: usage, nodejs, net
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/script.js" <<'JS'
const assert = require('assert');
const net = require('net');
let accepted = 0;
let remote = '';
const server = net.createServer((sock) => {
  accepted += 1;
  remote = sock.remoteAddress || '';
  sock.end();
});
server.listen(0, '127.0.0.1', () => {
  const { port } = server.address();
  const client = net.connect(port, '127.0.0.1');
  client.on('end', () => {
    server.close(() => {
      assert.strictEqual(accepted, 1, 'accepted=' + accepted);
      assert.ok(remote.startsWith('127.') || remote === '::ffff:127.0.0.1', 'remote=' + remote);
      console.log('OK net.accept');
    });
  });
});
JS

node "$tmpdir/script.js" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'OK net.accept'
