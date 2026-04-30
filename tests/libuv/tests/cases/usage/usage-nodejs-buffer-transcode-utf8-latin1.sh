#!/usr/bin/env bash
# @testcase: usage-nodejs-buffer-transcode-utf8-latin1
# @title: Node.js buffer.transcode utf8 to latin1
# @description: Uses buffer.transcode to convert a UTF-8 encoded buffer containing Latin-1 representable characters into a latin1 encoded buffer and verifies the resulting byte length and decoded string.
# @timeout: 60
# @tags: usage, nodejs, buffer
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/run.js" <<'JS'
const assert = require('assert');
const { transcode } = require('buffer');

const text = 'café résumé';
const utf8 = Buffer.from(text, 'utf8');
assert.ok(utf8.length > text.length, 'utf8 encodes accents as multi-byte');

const latin1 = transcode(utf8, 'utf8', 'latin1');
assert.strictEqual(latin1.length, text.length, 'latin1 must be one byte per char');
assert.strictEqual(latin1.toString('latin1'), text);

const back = transcode(latin1, 'latin1', 'utf8');
assert.ok(back.equals(utf8), 'utf8 round trip must match');

console.log('OK transcode utf8=%d latin1=%d text=%s', utf8.length, latin1.length, latin1.toString('latin1'));
JS

node "$tmpdir/run.js" >"$tmpdir/out"

validator_assert_contains "$tmpdir/out" 'OK transcode utf8=14 latin1=11 text=caf'
