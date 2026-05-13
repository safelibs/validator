#!/usr/bin/env bash
# @testcase: usage-nodejs-r16-http-loopback-chunked-length-sum
# @title: Node.js http server emits two chunks whose body length sum matches the client receive count
# @description: Starts an http server on 127.0.0.1:0 that writes two fixed chunks ("alpha-" and "beta") before ending the response, fires an http.request against it, accumulates all received data on the client and asserts the joined body equals "alpha-beta" with byte length 10 — exercising Node.js's libuv-backed http transport.
# @timeout: 60
# @tags: usage, nodejs, http
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/script.js" <<'JS'
const assert = require('assert');
const http = require('http');
const server = http.createServer((req, res) => {
  res.writeHead(200, { 'Content-Type': 'text/plain' });
  res.write('alpha-');
  res.end('beta');
});
server.listen(0, '127.0.0.1', () => {
  const { port } = server.address();
  http.request({ host: '127.0.0.1', port, method: 'GET', path: '/' }, (res) => {
    const chunks = [];
    res.on('data', (c) => chunks.push(c));
    res.on('end', () => {
      const body = Buffer.concat(chunks).toString('utf8');
      assert.strictEqual(body, 'alpha-beta');
      assert.strictEqual(body.length, 10);
      server.close(() => console.log('OK http.chunked'));
    });
  }).end();
});
JS

node "$tmpdir/script.js" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'OK http.chunked'
