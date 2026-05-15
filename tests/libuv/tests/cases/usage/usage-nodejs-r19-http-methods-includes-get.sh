#!/usr/bin/env bash
# @testcase: usage-nodejs-r19-http-methods-includes-get
# @title: Node.js http.METHODS exposes the standard HTTP verbs including GET POST PUT DELETE
# @description: Imports the http module, asserts http.METHODS is an Array with non-zero length, asserts every entry is an upper-case string, and asserts the verbs 'GET', 'POST', 'PUT', 'DELETE', 'HEAD', 'OPTIONS', and 'PATCH' are all present (case-sensitive), confirming the libuv-hosted HTTP parser exposes the expected verb registry.
# @timeout: 60
# @tags: usage, nodejs, http, methods, r19
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/script.js" <<'JS'
const assert = require('assert');
const http = require('http');
assert.ok(Array.isArray(http.METHODS));
assert.ok(http.METHODS.length > 0);
for (const m of http.METHODS) {
  assert.strictEqual(typeof m, 'string');
  assert.strictEqual(m, m.toUpperCase());
}
for (const v of ['GET', 'POST', 'PUT', 'DELETE', 'HEAD', 'OPTIONS', 'PATCH']) {
  assert.ok(http.METHODS.includes(v), 'missing ' + v);
}
console.log('OK methods.count=' + http.METHODS.length);
JS

node "$tmpdir/script.js" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'OK methods.count='
