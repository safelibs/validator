#!/usr/bin/env bash
# @testcase: usage-nodejs-crypto-timingsafeequal-constant-time
# @title: Node.js crypto.timingSafeEqual
# @description: Verifies crypto.timingSafeEqual returns true for identical buffers and false for differing ones of equal length.
# @timeout: 120
# @tags: usage, nodejs, crypto
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-nodejs-crypto-timingsafeequal-constant-time"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/script.js" <<'JS'
const crypto = require('crypto');
const a = Buffer.from('0123456789abcdef0123456789abcdef', 'utf8');
const b = Buffer.from('0123456789abcdef0123456789abcdef', 'utf8');
const c = Buffer.from('0123456789abcdef0123456789abcde0', 'utf8');
if (!crypto.timingSafeEqual(a, b)) {
  throw new Error('expected equal buffers to compare equal');
}
if (crypto.timingSafeEqual(a, c)) {
  throw new Error('expected differing buffers to compare unequal');
}
let lengthMismatch = false;
try {
  crypto.timingSafeEqual(a, Buffer.from('short'));
} catch (err) {
  lengthMismatch = true;
}
if (!lengthMismatch) throw new Error('expected length-mismatch to throw');
console.log('timingsafe ok equal=true unequal=false length-mismatch-throws=true');
JS

node "$tmpdir/script.js" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'timingsafe ok equal=true unequal=false length-mismatch-throws=true'
