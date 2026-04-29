#!/usr/bin/env bash
# @testcase: usage-nodejs-crypto-randombytes-async-batch11
# @title: Node.js randomBytes async
# @description: Generates random bytes through the asynchronous Node.js crypto callback.
# @timeout: 180
# @tags: usage, nodejs, libuv
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-nodejs-crypto-randombytes-async-batch11"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

node >"$tmpdir/out" <<'JS'
const crypto = require('crypto');
crypto.randomBytes(16, (err, buf) => {
  if (err) throw err;
  console.log(buf.length);
});
JS
validator_assert_contains "$tmpdir/out" '16'
