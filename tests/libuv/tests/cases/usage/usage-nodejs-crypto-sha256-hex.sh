#!/usr/bin/env bash
# @testcase: usage-nodejs-crypto-sha256-hex
# @title: nodejs crypto sha256 hex
# @description: Computes a SHA-256 hex digest with Node crypto.createHash and verifies the deterministic digest of a known input.
# @timeout: 180
# @tags: usage, nodejs, crypto
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-nodejs-crypto-sha256-hex"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

node >"$tmpdir/out" <<'JS'
const crypto = require('crypto');
console.log(crypto.createHash('sha256').update('validator').digest('hex'));
JS
validator_assert_contains "$tmpdir/out" 'f82af32160bc53112ca118abbf57fa6fed47eb90291a1d1d92f438ae2ed74ef6'
