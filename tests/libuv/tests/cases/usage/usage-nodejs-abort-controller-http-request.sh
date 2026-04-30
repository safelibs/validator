#!/usr/bin/env bash
# @testcase: usage-nodejs-abort-controller-http-request
# @title: Node.js AbortController cancels http request
# @description: Issues an http request against a slow loopback server and aborts it via AbortController, then verifies the abort error.
# @timeout: 180
# @tags: usage, event-loop, network, abort
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

node >"$tmpdir/out" <<'JS'
const assert = require('assert');
const http = require('http');

const server = http.createServer((req, res) => {
  // Never send a response — we want the client to abort first.
});
server.on('error', (e) => { throw e; });

server.listen(0, '127.0.0.1', () => {
  const port = server.address().port;
  const controller = new AbortController();
  const req = http.request({
    host: '127.0.0.1',
    port,
    path: '/slow',
    signal: controller.signal,
  });
  req.on('error', (err) => {
    assert.ok(err);
    assert.ok(err.name === 'AbortError' || err.code === 'ABORT_ERR' || /abort/i.test(err.message),
      'expected abort error, got ' + (err && err.stack || err));
    server.close();
    console.log('OK aborted', err.name || err.code);
  });
  req.end();
  setTimeout(() => controller.abort(), 25);
});
JS

validator_assert_contains "$tmpdir/out" 'OK aborted'
