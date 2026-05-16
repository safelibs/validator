#!/usr/bin/env bash
# @testcase: usage-nodejs-r21-worker-threads-message-roundtrip
# @title: Node.js Worker thread postMessage round-trips a JSON-cloneable payload
# @description: Spawns a Worker via worker_threads with an inline data: eval source that listens on parentPort and echoes any message; the main thread postMessages an object payload, awaits the 'message' event, and asserts the echoed payload deep-equals the sent payload, exercising libuv's thread pool and Node's structured-clone messaging.
# @timeout: 60
# @tags: usage, worker, threads, nodejs, r21
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/s.js" <<'JS'
const assert = require('assert');
const { Worker } = require('worker_threads');

const worker = new Worker(
  "const { parentPort } = require('worker_threads');" +
    "parentPort.on('message', (m) => parentPort.postMessage(m));",
  { eval: true }
);

const payload = { hello: 'r21', n: 42, arr: [1, 2, 3] };
worker.on('message', (echo) => {
  assert.deepStrictEqual(echo, payload, 'echo=' + JSON.stringify(echo));
  worker.terminate().then(() => console.log('OK worker echo n=' + echo.n));
});
worker.postMessage(payload);
JS

node "$tmpdir/s.js" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'OK worker echo'
