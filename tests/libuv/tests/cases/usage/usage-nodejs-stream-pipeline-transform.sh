#!/usr/bin/env bash
# @testcase: usage-nodejs-stream-pipeline-transform
# @title: Node.js stream.pipeline fs read -> Transform -> fs write
# @description: Pipes a source file through a Transform that uppercases bytes into a destination file and asserts the round-trip output.
# @timeout: 180
# @tags: usage, event-loop, stream, fs
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

WORK_DIR="$tmpdir" node >"$tmpdir/out" <<'JS'
const assert = require('assert');
const fs = require('fs');
const fsp = require('fs/promises');
const path = require('path');
const { Transform } = require('stream');
const { pipeline } = require('stream/promises');

(async () => {
  const root = process.env.WORK_DIR;
  const src = path.join(root, 'in.txt');
  const dst = path.join(root, 'out.txt');
  await fsp.writeFile(src, 'pipeline payload\n');

  const upper = new Transform({
    transform(chunk, _enc, cb) {
      cb(null, Buffer.from(chunk.toString('utf8').toUpperCase()));
    },
  });

  await pipeline(fs.createReadStream(src), upper, fs.createWriteStream(dst));

  const body = await fsp.readFile(dst, 'utf8');
  assert.strictEqual(body, 'PIPELINE PAYLOAD\n');

  console.log('OK pipeline-transform', body.trim());
})().catch((e) => { console.error(e); process.exit(1); });
JS

validator_assert_contains "$tmpdir/out" 'OK pipeline-transform PIPELINE PAYLOAD'
