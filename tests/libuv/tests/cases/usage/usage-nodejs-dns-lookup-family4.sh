#!/usr/bin/env bash
# @testcase: usage-nodejs-dns-lookup-family4
# @title: Node.js dns.lookup localhost with family=4
# @description: Resolves localhost via dns.lookup with the family option set to 4 and asserts the address is 127.0.0.1 with family 4.
# @timeout: 120
# @tags: usage, event-loop, dns
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

node >"$tmpdir/out" <<'JS'
const assert = require('assert');
const dns = require('dns');

dns.lookup('localhost', { family: 4 }, (err, address, family) => {
  if (err) { console.error(err); process.exit(1); }
  assert.strictEqual(family, 4, 'family must be 4');
  assert.strictEqual(address, '127.0.0.1', 'address must be 127.0.0.1');
  console.log('OK lookup4', address, family);
});
JS

validator_assert_contains "$tmpdir/out" 'OK lookup4 127.0.0.1 4'
