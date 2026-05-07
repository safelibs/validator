#!/usr/bin/env bash
# @testcase: usage-nodejs-r13-stream-pipeline-async-promise
# @title: Node.js stream/promises pipeline writes a Readable iterable into a file
# @description: Awaits stream.promises.pipeline of a Readable.from iterable into fs.createWriteStream and asserts the destination file contains the concatenated chunks in order.
# @timeout: 60
# @tags: usage, stream, promises, nodejs
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/script.js" <<JS
const assert = require('assert');
const fs = require('fs');
const fsp = require('fs/promises');
const { Readable } = require('stream');
const { pipeline } = require('stream/promises');
(async () => {
  const file = '$tmpdir/out.txt';
  await pipeline(Readable.from(['alpha-', 'beta-', 'gamma\n']), fs.createWriteStream(file));
  const body = await fsp.readFile(file, 'utf8');
  assert.strictEqual(body, 'alpha-beta-gamma\n');
  console.log('OK pipeline.async');
})().catch((e) => { console.error(e); process.exit(1); });
JS

node "$tmpdir/script.js" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'OK pipeline.async'
