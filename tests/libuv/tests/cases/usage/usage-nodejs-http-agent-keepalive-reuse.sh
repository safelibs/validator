#!/usr/bin/env bash
# @testcase: usage-nodejs-http-agent-keepalive-reuse
# @title: Node.js http.Agent keep-alive socket reuse
# @description: Issues two sequential HTTP requests through a keep-alive Agent on loopback and verifies the same TCP socket port is reused.
# @timeout: 180
# @tags: usage, event-loop, network, http
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

node >"$tmpdir/out" <<'JS'
const http = require('http');

const ports = new Set();
const server = http.createServer((req, res) => {
  ports.add(req.socket.remotePort);
  res.setHeader('Content-Type', 'text/plain');
  res.end('keepalive');
});
server.on('error', (e) => { console.error(e); process.exit(1); });

server.listen(0, '127.0.0.1', () => {
  const port = server.address().port;
  const agent = new http.Agent({ keepAlive: true, maxSockets: 1 });

  function request() {
    return new Promise((resolve, reject) => {
      http.get({ host: '127.0.0.1', port, path: '/', agent }, (res) => {
        let body = '';
        res.setEncoding('utf8');
        res.on('data', (c) => { body += c; });
        res.on('end', () => resolve(body));
      }).on('error', reject);
    });
  }

  (async () => {
    const a = await request();
    const b = await request();
    agent.destroy();
    server.close();
    if (a !== 'keepalive' || b !== 'keepalive') {
      console.error('bodies', a, b);
      process.exit(1);
    }
    if (ports.size !== 1) {
      console.error('expected single client port, saw', [...ports]);
      process.exit(1);
    }
    console.log('OK keepalive-reuse', ports.size);
  })();
});
JS

validator_assert_contains "$tmpdir/out" 'OK keepalive-reuse 1'
