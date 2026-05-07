#!/usr/bin/env bash
# @testcase: usage-nodejs-r12-dns-resolve4-localhost
# @title: Node.js dns.lookup of localhost resolves to a loopback IPv4 address
# @description: Calls dns.lookup('localhost', {family:4}) and asserts the resolved address is in the 127.0.0.0/8 range with family 4.
# @timeout: 60
# @tags: usage, dns, nodejs
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/script.js" <<'JS'
const assert = require('assert');
const dns = require('dns');
dns.lookup('localhost', { family: 4 }, (err, address, family) => {
  if (err) throw err;
  assert.strictEqual(family, 4);
  assert.ok(/^127\./.test(address), 'address='+address);
  console.log('OK dns.lookup', address);
});
JS

node "$tmpdir/script.js" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'OK dns.lookup 127.'
