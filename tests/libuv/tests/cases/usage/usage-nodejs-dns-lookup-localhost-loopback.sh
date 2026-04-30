#!/usr/bin/env bash
# @testcase: usage-nodejs-dns-lookup-localhost-loopback
# @title: Node.js dns.lookup localhost resolves to loopback
# @description: Calls dns.lookup('localhost') and asserts the resolved address is 127.0.0.1 with family 4.
# @timeout: 180
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
  if (err) throw err;
  assert.strictEqual(family, 4);
  assert.strictEqual(address, '127.0.0.1');
  console.log('OK lookup', address, 'family', family);
});
JS

validator_assert_contains "$tmpdir/out" 'OK lookup 127.0.0.1 family 4'
