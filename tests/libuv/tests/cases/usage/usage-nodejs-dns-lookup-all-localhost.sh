#!/usr/bin/env bash
# @testcase: usage-nodejs-dns-lookup-all-localhost
# @title: Node.js dns.lookup all:true returns array
# @description: Resolves localhost via dns.lookup with all:true and verifies the returned array contains 127.0.0.1 with family 4.
# @timeout: 120
# @tags: usage, event-loop, dns
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

node >"$tmpdir/out" <<'JS'
const dns = require('dns');
dns.lookup('localhost', { all: true, family: 4 }, (err, addrs) => {
  if (err) { console.error(err); process.exit(1); }
  if (!Array.isArray(addrs) || addrs.length === 0) {
    console.error('expected non-empty array, got', addrs);
    process.exit(1);
  }
  const hit = addrs.find((a) => a.address === '127.0.0.1' && a.family === 4);
  if (!hit) { console.error('no 127.0.0.1 entry', addrs); process.exit(1); }
  console.log('OK lookup-all', hit.address, hit.family);
});
JS

validator_assert_contains "$tmpdir/out" 'OK lookup-all 127.0.0.1 4'
