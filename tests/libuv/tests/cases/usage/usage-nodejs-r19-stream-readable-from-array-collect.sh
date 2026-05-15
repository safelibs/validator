#!/usr/bin/env bash
# @testcase: usage-nodejs-r19-stream-readable-from-array-collect
# @title: Node.js stream.Readable.from(array) emits each element in order through async iteration
# @description: Creates a Readable stream via Readable.from(['a', 'b', 'c', 'd']), consumes it with for-await-of into a JavaScript array, and asserts the collected array deep-equals ['a','b','c','d'] preserving order and arity, exercising libuv-hosted stream iteration semantics.
# @timeout: 60
# @tags: usage, nodejs, stream, readable, iterator, r19
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/script.js" <<'JS'
const assert = require('assert');
const { Readable } = require('stream');
(async () => {
  const src = ['a', 'b', 'c', 'd'];
  const r = Readable.from(src);
  const got = [];
  for await (const x of r) got.push(x);
  assert.deepStrictEqual(got, src);
  console.log('OK readable.from.count=' + got.length);
})().catch((e) => { console.error(e); process.exit(1); });
JS

node "$tmpdir/script.js" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'OK readable.from.count=4'
