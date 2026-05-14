#!/usr/bin/env bash
# @testcase: usage-nodejs-r17-stream-readable-from-pipe-bytes
# @title: Node.js stream.Readable.from(['abc']) piped to a Writable writes exactly 3 bytes
# @description: Builds a Readable stream from the in-memory array ['abc'], pipes it into a Writable that concatenates chunks, awaits 'finish', and asserts the final collected buffer is exactly the 3-byte string 'abc' — exercising libuv-backed Node.js stream plumbing.
# @timeout: 60
# @tags: usage, nodejs, stream, pipe, r17
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/script.js" <<'JS'
const assert = require('assert');
const { Readable, Writable } = require('stream');

const chunks = [];
const w = new Writable({
  write(chunk, _enc, cb) { chunks.push(Buffer.from(chunk)); cb(); }
});

const r = Readable.from(['abc']);
r.pipe(w);

w.on('finish', () => {
  const out = Buffer.concat(chunks);
  assert.strictEqual(out.length, 3);
  assert.strictEqual(out.toString('utf8'), 'abc');
  console.log('OK stream.bytes=' + out.length);
});
JS

node "$tmpdir/script.js" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'OK stream.bytes=3'
