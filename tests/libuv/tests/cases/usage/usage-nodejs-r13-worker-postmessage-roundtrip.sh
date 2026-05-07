#!/usr/bin/env bash
# @testcase: usage-nodejs-r13-worker-postmessage-roundtrip
# @title: Node.js worker_threads postMessage round-trips a payload from worker to parent
# @description: Spawns a Worker with eval=true that listens for a parent message and posts back the squared value, then asserts the parent receives the expected response and the worker exits cleanly with code 0.
# @timeout: 60
# @tags: usage, worker, nodejs
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/script.js" <<'JS'
const assert = require('assert');
const { Worker } = require('worker_threads');
const code = `
  const { parentPort } = require('worker_threads');
  parentPort.on('message', (n) => {
    parentPort.postMessage(n * n);
    parentPort.close();
  });
`;
const worker = new Worker(code, { eval: true });
worker.once('message', (v) => {
  assert.strictEqual(v, 49);
});
worker.once('exit', (code) => {
  assert.strictEqual(code, 0, 'exit='+code);
  console.log('OK worker.postMessage');
});
worker.postMessage(7);
JS

node "$tmpdir/script.js" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'OK worker.postMessage'
