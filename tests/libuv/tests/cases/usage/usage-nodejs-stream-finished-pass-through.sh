#!/usr/bin/env bash
# @testcase: usage-nodejs-stream-finished-pass-through
# @title: Node.js stream finished
# @description: Awaits Node.js stream/promises.finished on a PassThrough stream and verifies the captured payload after the writable side ends.
# @timeout: 180
# @tags: usage, nodejs, stream
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-nodejs-stream-finished-pass-through"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

node >"$tmpdir/out" <<'JS'
const { PassThrough } = require('stream');
const { finished } = require('stream/promises');
(async () => {
  const stream = new PassThrough();
  let output = '';
  stream.on('data', (chunk) => { output += chunk.toString('utf8'); });
  stream.end('finished payload');
  await finished(stream);
  console.log(output);
})();
JS
validator_assert_contains "$tmpdir/out" 'finished payload'
