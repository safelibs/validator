#!/usr/bin/env bash
# @testcase: usage-nodejs-r15-stream-passthrough-chunks
# @title: Node.js stream.PassThrough forwards all written chunks unchanged
# @description: Writes three string chunks into a stream.PassThrough, ends the stream, collects all data events, and asserts the concatenated UTF-8 buffer equals the joined source chunks.
# @timeout: 60
# @tags: usage, stream, nodejs
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/script.js" <<'JS'
const assert = require('assert');
const { PassThrough } = require('stream');
const pass = new PassThrough();
const chunks = [];
pass.on('data', (c) => chunks.push(c));
pass.on('end', () => {
  const collected = Buffer.concat(chunks).toString('utf8');
  assert.strictEqual(collected, 'r15-alpha|r15-beta|r15-gamma');
  console.log('OK PassThrough');
});
pass.write('r15-alpha|');
pass.write('r15-beta|');
pass.end('r15-gamma');
JS

node "$tmpdir/script.js" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'OK PassThrough'
