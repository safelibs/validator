#!/usr/bin/env bash
# @testcase: usage-nodejs-r18-dns-promises-lookup-localhost
# @title: Node.js dns.promises.lookup('localhost') resolves to a loopback address
# @description: Calls require('dns').promises.lookup('localhost') with default options, awaits the result, asserts the returned object has a string "address" property, asserts the family is either 4 or 6, and asserts the address starts with "127." (IPv4 loopback) or equals "::1" (IPv6 loopback), exercising libuv-backed name resolution via the threadpool getaddrinfo path.
# @timeout: 60
# @tags: usage, nodejs, dns, lookup, localhost, r18
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/script.js" <<'JS'
const assert = require('assert');
const dns = require('dns').promises;
(async () => {
  const r = await dns.lookup('localhost');
  assert.strictEqual(typeof r.address, 'string');
  assert.ok(r.family === 4 || r.family === 6, 'family=' + r.family);
  const ok = r.address.startsWith('127.') || r.address === '::1';
  assert.ok(ok, 'address=' + r.address);
  console.log('OK lookup.address=' + r.address + ' family=' + r.family);
})().catch((e) => { console.error(e); process.exit(1); });
JS

node "$tmpdir/script.js" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'OK lookup.address='
