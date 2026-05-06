#!/usr/bin/env bash
# @testcase: usage-nodejs-r10-http-server-trailers-loopback
# @title: Node.js http server addTrailers chunked response
# @description: Starts an http.Server on 127.0.0.1, writes a chunked response with addTrailers, requests it via http.get, and asserts the trailers object on the client response carries the expected key/value pair.
# @timeout: 60
# @tags: usage, http, nodejs
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

node - <<'JS'
const http = require('http');
const assert = require('assert');

const server = http.createServer((req, res) => {
  res.writeHead(200, { 'Content-Type': 'text/plain', Trailer: 'X-Final' });
  res.write('hello');
  res.addTrailers({ 'X-Final': 'done' });
  res.end();
});

server.listen(0, '127.0.0.1', () => {
  const { port } = server.address();
  http.get({ host: '127.0.0.1', port, path: '/' }, (res) => {
    const chunks = [];
    res.on('data', (c) => chunks.push(c));
    res.on('end', () => {
      const body = Buffer.concat(chunks).toString();
      assert.strictEqual(body, 'hello');
      assert.strictEqual(res.trailers['x-final'], 'done');
      server.close();
    });
  }).on('error', (e) => { throw e; });
});
JS
