#!/usr/bin/env bash
# @testcase: usage-nodejs-crypto-randomfill
# @title: Node.js crypto randomFill
# @description: Fills a buffer asynchronously with crypto.randomFill and verifies the resulting buffer length.
# @timeout: 180
# @tags: usage, nodejs, crypto
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-nodejs-crypto-randomfill"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

node >"$tmpdir/out" <<'JS'
const crypto = require('crypto');
const buffer = Buffer.alloc(8);
crypto.randomFill(buffer, (error, filled) => {
  if (error) throw error;
  console.log(filled.length);
});
JS
validator_assert_contains "$tmpdir/out" '8'
