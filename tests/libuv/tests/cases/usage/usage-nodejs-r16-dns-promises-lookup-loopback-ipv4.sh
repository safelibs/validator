#!/usr/bin/env bash
# @testcase: usage-nodejs-r16-dns-promises-lookup-loopback-ipv4
# @title: Node.js dns.promises.lookup resolves localhost-style hostname to 127.0.0.1 in family 4
# @description: Awaits dns.promises.lookup('127.0.0.1', {family: 4}), asserts the resolved address equals '127.0.0.1' and the returned family equals 4 — exercising Node.js's libuv getaddrinfo path for a numeric IPv4 host.
# @timeout: 60
# @tags: usage, nodejs, dns
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/script.js" <<'JS'
const assert = require('assert');
const dns = require('dns').promises;
(async () => {
  const r = await dns.lookup('127.0.0.1', { family: 4 });
  assert.strictEqual(r.address, '127.0.0.1');
  assert.strictEqual(r.family, 4);
  console.log('OK dns.lookup');
})().catch((e) => { console.error(e); process.exit(1); });
JS

node "$tmpdir/script.js" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'OK dns.lookup'
