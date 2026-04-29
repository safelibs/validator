#!/usr/bin/env bash
# @testcase: usage-nodejs-buffer-from-hex
# @title: nodejs buffer from hex
# @description: Decodes a hex-encoded ASCII buffer through Node Buffer and verifies the restored UTF-8 string.
# @timeout: 180
# @tags: usage, nodejs, buffer
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-nodejs-buffer-from-hex"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

node >"$tmpdir/out" <<'JS'
const buf = Buffer.from('48656c6c6f', 'hex');
console.log(buf.toString('utf8'));
JS
validator_assert_contains "$tmpdir/out" 'Hello'
