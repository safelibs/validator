#!/usr/bin/env bash
# @testcase: usage-nodejs-stream-finished
# @title: Node.js stream finished callback
# @description: Uses stream.finished on a PassThrough stream and verifies the collected payload.
# @timeout: 180
# @tags: usage, nodejs, stream
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-nodejs-stream-finished"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

node >"$tmpdir/out" <<'JS'
const { PassThrough, finished } = require('stream');
const stream = new PassThrough();
let data = '';
stream.on('data', (chunk) => { data += chunk.toString('utf8'); });
finished(stream, (error) => {
  if (error) throw error;
  console.log(data);
});
stream.end('stream-finished');
JS
validator_assert_contains "$tmpdir/out" 'stream-finished'
