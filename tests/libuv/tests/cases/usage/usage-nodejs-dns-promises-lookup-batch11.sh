#!/usr/bin/env bash
# @testcase: usage-nodejs-dns-promises-lookup-batch11
# @title: Node.js DNS promises lookup
# @description: Looks up localhost through Node.js dns.promises.
# @timeout: 180
# @tags: usage, nodejs, libuv
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-nodejs-dns-promises-lookup-batch11"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

node >"$tmpdir/out" <<'JS'
const dns = require('dns').promises;
(async () => {
  const result = await dns.lookup('localhost');
  console.log(result.address.length > 0);
})().catch(err => { console.error(err); process.exit(1); });
JS
validator_assert_contains "$tmpdir/out" 'true'
