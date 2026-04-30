#!/usr/bin/env bash
# @testcase: usage-nodejs-net-server-maxconnections
# @title: Node.js net.Server maxConnections enforcement
# @description: Configures net.Server.maxConnections=1, opens two clients, and verifies the second connection is dropped while the first is served.
# @timeout: 180
# @tags: usage, nodejs, network
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

node >"$tmpdir/out" <<'JS'
const assert = require('assert');
const net = require('net');

(async () => {
  const accepted = [];
  const server = net.createServer((socket) => {
    accepted.push(true);
    socket.write('hello\n');
    // Hold the first connection for a moment so the second arrives while at cap.
    setTimeout(() => socket.end(), 150);
  });
  server.maxConnections = 1;

  await new Promise((resolve, reject) => {
    server.once('error', reject);
    server.listen(0, '127.0.0.1', resolve);
  });
  const port = server.address().port;

  function connectAndCollect() {
    return new Promise((resolve) => {
      const sock = net.createConnection({ host: '127.0.0.1', port });
      let body = '';
      let closedWithoutData = false;
      sock.on('data', (c) => { body += c.toString('utf8'); });
      sock.on('end', () => resolve({ body, closedWithoutData }));
      sock.on('close', (hadError) => {
        if (body === '') closedWithoutData = true;
        resolve({ body, closedWithoutData });
      });
      sock.on('error', () => resolve({ body, closedWithoutData: true }));
    });
  }

  const first = connectAndCollect();
  // Slight delay so server sees first connection before the second.
  await new Promise((r) => setTimeout(r, 30));
  const second = connectAndCollect();

  const [a, b] = await Promise.all([first, second]);
  await new Promise((resolve) => server.close(resolve));

  assert.strictEqual(a.body, 'hello\n', 'first client must be served');
  assert.strictEqual(b.body, '', 'second client must be dropped at cap');
  assert.strictEqual(accepted.length, 1, `expected 1 accepted connection, got ${accepted.length}`);
  console.log('OK maxconn', accepted.length, a.body.trim());
})().catch((err) => {
  console.error(err && err.stack || err);
  process.exit(1);
});
JS

validator_assert_contains "$tmpdir/out" 'OK maxconn 1 hello'
