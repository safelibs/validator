#!/usr/bin/env bash
# @testcase: usage-nodejs-stream-finished-promise-batch11
# @title: Node.js stream finished promise
# @description: Waits for a Node.js writable stream to finish through stream promises.
# @timeout: 180
# @tags: usage, nodejs, libuv
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-nodejs-stream-finished-promise-batch11"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

OUT_PATH="$tmpdir/stream.txt" node >"$tmpdir/out" <<'JS'
const fs = require('fs');
const { finished } = require('stream/promises');
(async () => {
  const ws = fs.createWriteStream(process.env.OUT_PATH);
  ws.end('finished payload');
  await finished(ws);
  console.log(fs.readFileSync(process.env.OUT_PATH, 'utf8'));
})().catch(err => { console.error(err); process.exit(1); });
JS
validator_assert_contains "$tmpdir/out" 'finished payload'
