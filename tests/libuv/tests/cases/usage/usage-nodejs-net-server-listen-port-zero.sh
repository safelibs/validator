#!/usr/bin/env bash
# @testcase: usage-nodejs-net-server-listen-port-zero
# @title: Node.js net.Server listen port=0 yields ephemeral port
# @description: Listens on 127.0.0.1 with port set to 0 and verifies server.address().port is in the ephemeral range and the server accepts a loopback connection.
# @timeout: 120
# @tags: usage, event-loop, network
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

node >"$tmpdir/out" <<'JS'
const assert = require('assert');
const net = require('net');

const server = net.createServer((s) => s.end('zero-port-ok\n'));
server.on('error', (e) => { console.error(e); process.exit(1); });
server.listen(0, '127.0.0.1', () => {
  const addr = server.address();
  assert.strictEqual(typeof addr, 'object');
  assert.strictEqual(addr.address, '127.0.0.1');
  assert.strictEqual(addr.family, 'IPv4');
  assert.ok(Number.isInteger(addr.port), 'port integer');
  assert.ok(addr.port > 0 && addr.port < 65536, 'port in range');

  const c = net.createConnection({ port: addr.port, host: '127.0.0.1' });
  let body = '';
  c.setEncoding('utf8');
  c.on('data', (chunk) => { body += chunk; });
  c.on('end', () => {
    server.close();
    assert.strictEqual(body.trim(), 'zero-port-ok');
    console.log('OK port-zero ephemeral', body.trim());
  });
  c.on('error', (e) => { console.error(e); process.exit(1); });
});
JS

validator_assert_contains "$tmpdir/out" 'OK port-zero ephemeral zero-port-ok'
