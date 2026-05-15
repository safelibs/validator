#!/usr/bin/env bash
# @testcase: usage-nodejs-r20-stream-pipeline-async-success
# @title: Node.js stream/promises pipeline completes for a readable-to-writable file copy
# @description: Writes a known byte payload to a source file, uses fs.createReadStream and fs.createWriteStream wired via stream/promises.pipeline to copy it to a destination, awaits the pipeline promise, reads the destination back and asserts it equals the source bytes, confirming libuv-backed stream pipelining succeeds for a trivial file copy.
# @timeout: 60
# @tags: usage, nodejs, stream, pipeline, r20
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'pipeline-r20-payload-bytes\n' >"$tmpdir/src"

cat >"$tmpdir/script.js" <<'JS'
const assert = require('assert');
const fs = require('fs');
const { pipeline } = require('stream/promises');
const src = process.argv[2];
const dst = process.argv[3];
(async () => {
  await pipeline(fs.createReadStream(src), fs.createWriteStream(dst));
  const a = fs.readFileSync(src);
  const b = fs.readFileSync(dst);
  assert.deepStrictEqual(a, b);
  console.log('OK pipeline bytes=' + a.length);
})().catch((e) => { console.error(e); process.exit(1); });
JS

node "$tmpdir/script.js" "$tmpdir/src" "$tmpdir/dst" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'OK pipeline bytes='
