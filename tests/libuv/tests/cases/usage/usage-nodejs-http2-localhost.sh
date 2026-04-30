#!/usr/bin/env bash
# @testcase: usage-nodejs-http2-localhost
# @title: Node.js http2 loopback request
# @description: Starts an http2 server on 127.0.0.1 with allowHTTP1 and exchanges a single request via the http2 client.
# @timeout: 180
# @tags: usage, event-loop, network, http2
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

node >"$tmpdir/out" <<'JS'
const assert = require('assert');
const http2 = require('http2');

const server = http2.createServer();
server.on('stream', (stream, headers) => {
  assert.strictEqual(headers[':path'], '/ping');
  stream.respond({ ':status': 200, 'content-type': 'text/plain' });
  stream.end('http2-pong');
});
server.on('error', (e) => { throw e; });

server.listen(0, '127.0.0.1', () => {
  const port = server.address().port;
  const client = http2.connect(`http://127.0.0.1:${port}`);
  client.on('error', (e) => { throw e; });
  const req = client.request({ ':path': '/ping' });
  let body = '';
  let status = 0;
  req.setEncoding('utf8');
  req.on('response', (headers) => { status = headers[':status']; });
  req.on('data', (chunk) => { body += chunk; });
  req.on('end', () => {
    assert.strictEqual(status, 200);
    assert.strictEqual(body, 'http2-pong');
    client.close();
    server.close();
    console.log('OK http2', body);
  });
  req.end();
});
JS

validator_assert_contains "$tmpdir/out" 'OK http2 http2-pong'
