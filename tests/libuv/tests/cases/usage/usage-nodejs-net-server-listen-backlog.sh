#!/usr/bin/env bash
# @testcase: usage-nodejs-net-server-listen-backlog
# @title: Node.js net server listen with backlog parameter
# @description: Calls server.listen with an explicit backlog argument and verifies the bound socket still accepts a loopback client connection.
# @timeout: 120
# @tags: usage, event-loop, network
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

node >"$tmpdir/out" <<'JS'
const net = require('net');
const server = net.createServer((s) => s.end('backlog-ok\n'));
server.on('error', (e) => { console.error(e); process.exit(1); });
server.listen(0, '127.0.0.1', 16, () => {
  const port = server.address().port;
  const c = net.createConnection({ port, host: '127.0.0.1' });
  let body = '';
  c.setEncoding('utf8');
  c.on('data', (chunk) => { body += chunk; });
  c.on('end', () => {
    server.close();
    if (body.trim() !== 'backlog-ok') { console.error('body', body); process.exit(1); }
    console.log('OK backlog', port > 0 ? 'bound' : 'unbound', body.trim());
  });
  c.on('error', (e) => { console.error(e); process.exit(1); });
});
JS

validator_assert_contains "$tmpdir/out" 'OK backlog bound backlog-ok'
