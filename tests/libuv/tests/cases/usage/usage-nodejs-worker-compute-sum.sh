#!/usr/bin/env bash
# @testcase: usage-nodejs-worker-compute-sum
# @title: Node.js worker_threads compute sum
# @description: Spawns a worker thread that computes a deterministic sum and verifies the result on the main thread.
# @timeout: 180
# @tags: usage, event-loop, worker
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

node >"$tmpdir/out" <<'JS'
const assert = require('assert');
const { Worker } = require('worker_threads');

const code = `
  const { parentPort, workerData } = require('worker_threads');
  let total = 0;
  for (let i = 1; i <= workerData.n; i++) total += i;
  parentPort.postMessage(total);
`;

const worker = new Worker(code, { eval: true, workerData: { n: 1000 } });
worker.on('message', (sum) => {
  assert.strictEqual(sum, 500500);
  worker.terminate();
  console.log('OK sum', sum);
});
worker.on('error', (e) => { throw e; });
JS

validator_assert_contains "$tmpdir/out" 'OK sum 500500'
