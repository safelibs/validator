#!/usr/bin/env bash
# @testcase: usage-nodejs-r14-stream-readable-from-iterate
# @title: Node.js stream.Readable.from yields each item via async iteration
# @description: Builds a Readable stream from an array via stream.Readable.from and iterates it with for-await-of, asserting the collected sequence equals the source array element-for-element.
# @timeout: 60
# @tags: usage, stream, nodejs
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/script.js" <<'JS'
const assert = require('assert');
const { Readable } = require('stream');
(async () => {
  const source = ['alpha', 'beta', 'gamma'];
  const stream = Readable.from(source);
  const collected = [];
  for await (const item of stream) {
    collected.push(item);
  }
  assert.deepStrictEqual(collected, source);
  console.log('OK Readable.from');
})().catch(e => { console.error(e); process.exit(1); });
JS

node "$tmpdir/script.js" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'OK Readable.from'
