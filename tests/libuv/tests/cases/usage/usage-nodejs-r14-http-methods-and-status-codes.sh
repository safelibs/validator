#!/usr/bin/env bash
# @testcase: usage-nodejs-r14-http-methods-and-status-codes
# @title: Node.js http.METHODS lists GET/POST and STATUS_CODES maps 200 to OK
# @description: Reads http.METHODS and asserts it is a non-empty array containing at least 'GET', 'POST', 'PUT', 'DELETE', and 'HEAD', then verifies http.STATUS_CODES[200] equals 'OK' and STATUS_CODES[404] equals 'Not Found'.
# @timeout: 60
# @tags: usage, http, nodejs
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/script.js" <<'JS'
const assert = require('assert');
const http = require('http');
assert.ok(Array.isArray(http.METHODS), 'METHODS not array');
assert.ok(http.METHODS.length >= 5, 'len='+http.METHODS.length);
for (const m of ['GET', 'POST', 'PUT', 'DELETE', 'HEAD']) {
  assert.ok(http.METHODS.includes(m), 'missing '+m);
}
assert.strictEqual(http.STATUS_CODES[200], 'OK');
assert.strictEqual(http.STATUS_CODES[404], 'Not Found');
assert.strictEqual(http.STATUS_CODES[500], 'Internal Server Error');
console.log('OK http.METHODS+STATUS_CODES');
JS

node "$tmpdir/script.js" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'OK http.METHODS+STATUS_CODES'
