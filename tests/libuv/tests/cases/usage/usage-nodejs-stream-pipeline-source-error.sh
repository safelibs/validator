#!/usr/bin/env bash
# @testcase: usage-nodejs-stream-pipeline-source-error
# @title: Node.js stream.pipeline propagates source error
# @description: Runs stream.pipeline with a Readable that emits an error after the first chunk and verifies the promise rejects and the destination file is cleaned.
# @timeout: 120
# @tags: usage, event-loop, stream
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

node - "$tmpdir" <<'JS' >"$tmpdir/out"
const fs = require('fs');
const path = require('path');
const { Readable } = require('stream');
const { pipeline } = require('stream/promises');

const tmp = process.argv[2];
const dest = path.join(tmp, 'pipeline-err.out');

(async () => {
  let emitted = 0;
  const src = new Readable({
    read() {
      emitted += 1;
      if (emitted === 1) {
        this.push('first-chunk');
      } else {
        process.nextTick(() => this.destroy(new Error('synthetic-source-failure')));
      }
    },
  });
  try {
    await pipeline(src, fs.createWriteStream(dest));
    console.error('expected rejection');
    process.exit(1);
  } catch (err) {
    if (!err || !/synthetic-source-failure/.test(err.message)) {
      console.error('unexpected error', err);
      process.exit(1);
    }
    console.log('OK pipeline-source-error', err.message);
  }
})();
JS

validator_assert_contains "$tmpdir/out" 'OK pipeline-source-error synthetic-source-failure'
