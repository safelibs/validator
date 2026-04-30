#!/usr/bin/env bash
# @testcase: usage-nodejs-net-server-two-clients-concurrent
# @title: Node.js net server two concurrent clients
# @description: Binds a TCP server on 127.0.0.1 and accepts two concurrent client connections, verifying each receives its own greeting.
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

let connectCount = 0;
const server = net.createServer((sock) => {
  connectCount += 1;
  const id = connectCount;
  sock.end(`hello-${id}\n`);
});
server.on('error', (e) => { throw e; });

function fetch(port) {
  return new Promise((resolve, reject) => {
    const c = net.createConnection({ port, host: '127.0.0.1' });
    let body = '';
    c.setEncoding('utf8');
    c.on('data', (chunk) => { body += chunk; });
    c.on('end', () => resolve(body));
    c.on('error', reject);
  });
}

server.listen(0, '127.0.0.1', async () => {
  const port = server.address().port;
  const [a, b] = await Promise.all([fetch(port), fetch(port)]);
  server.close();
  const seen = new Set([a.trim(), b.trim()]);
  assert.strictEqual(seen.size, 2, 'expected two distinct greetings: ' + a + ' / ' + b);
  assert.ok(seen.has('hello-1'));
  assert.ok(seen.has('hello-2'));
  assert.strictEqual(connectCount, 2);
  console.log('OK two-clients', connectCount, [...seen].sort().join(','));
});
JS

validator_assert_contains "$tmpdir/out" 'OK two-clients 2 hello-1,hello-2'
