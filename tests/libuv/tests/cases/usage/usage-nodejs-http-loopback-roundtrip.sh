#!/usr/bin/env bash
# @testcase: usage-nodejs-http-loopback-roundtrip
# @title: Node.js http.createServer + http.request loopback round trip
# @description: Starts an http server on 127.0.0.1, issues an http.request POST, and asserts the echoed body matches with the expected Content-Length.
# @timeout: 180
# @tags: usage, event-loop, http
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

node >"$tmpdir/out" <<'JS'
const assert = require('assert');
const http = require('http');

const payload = 'http-loopback-payload';

const server = http.createServer((req, res) => {
  let body = '';
  req.setEncoding('utf8');
  req.on('data', (c) => { body += c; });
  req.on('end', () => {
    res.setHeader('Content-Type', 'text/plain');
    res.setHeader('Content-Length', Buffer.byteLength(body).toString());
    res.end(body);
  });
});

server.on('error', (e) => { throw e; });

server.listen(0, '127.0.0.1', () => {
  const port = server.address().port;
  const req = http.request(
    { host: '127.0.0.1', port, method: 'POST', path: '/echo', headers: { 'Content-Length': Buffer.byteLength(payload).toString() } },
    (res) => {
      assert.strictEqual(res.statusCode, 200);
      assert.strictEqual(res.headers['content-length'], String(Buffer.byteLength(payload)));
      let body = '';
      res.setEncoding('utf8');
      res.on('data', (c) => { body += c; });
      res.on('end', () => {
        assert.strictEqual(body, payload);
        server.close(() => {
          console.log('OK http', body, 'len', body.length);
        });
      });
    },
  );
  req.on('error', (e) => { throw e; });
  req.end(payload);
});
JS

validator_assert_contains "$tmpdir/out" 'OK http http-loopback-payload len 21'
