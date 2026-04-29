#!/usr/bin/env bash
# @testcase: usage-nodejs-crypto-randombytes
# @title: Node.js crypto randomBytes
# @description: Allocates random bytes through Node.js crypto and verifies the returned buffer length.
# @timeout: 180
# @tags: usage, nodejs, crypto
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-nodejs-crypto-randombytes"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

node >"$tmpdir/out" <<'JS'
const crypto = require('crypto');
const value = crypto.randomBytes(12);
console.log(value.length);
JS
validator_assert_contains "$tmpdir/out" '12'
