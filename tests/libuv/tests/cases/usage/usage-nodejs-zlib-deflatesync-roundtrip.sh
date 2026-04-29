#!/usr/bin/env bash
# @testcase: usage-nodejs-zlib-deflatesync-roundtrip
# @title: nodejs zlib deflate roundtrip
# @description: Round-trips a payload through Node zlib.deflateSync and zlib.inflateSync and verifies the restored bytes.
# @timeout: 180
# @tags: usage, nodejs, zlib
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-nodejs-zlib-deflatesync-roundtrip"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

node >"$tmpdir/out" <<'JS'
const zlib = require('zlib');
const compressed = zlib.deflateSync(Buffer.from('deflate payload'));
const restored = zlib.inflateSync(compressed).toString('utf8');
console.log(restored);
JS
validator_assert_contains "$tmpdir/out" 'deflate payload'
