#!/usr/bin/env bash
# @testcase: usage-nodejs-worker-share-env
# @title: Node.js worker_threads SHARE_ENV environment sharing
# @description: Spawns a worker_threads.Worker with env=worker_threads.SHARE_ENV, mutates process.env in the worker, and verifies the change is visible in the parent process.
# @timeout: 180
# @tags: usage, nodejs, worker
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/run.js" <<'JS'
const assert = require('assert');
const { Worker, SHARE_ENV, isMainThread, parentPort } = require('worker_threads');

if (!isMainThread) {
  process.env.VALIDATOR_SHARE_ENV = 'set-by-worker';
  parentPort.postMessage('done');
} else {
  delete process.env.VALIDATOR_SHARE_ENV;
  const worker = new Worker(__filename, { env: SHARE_ENV });

  (async () => {
    const msg = await new Promise((resolve, reject) => {
      worker.once('message', resolve);
      worker.once('error', reject);
    });
    assert.strictEqual(msg, 'done');
    await new Promise((resolve, reject) => {
      worker.once('exit', (code) => code === 0 ? resolve() : reject(new Error(`worker exit ${code}`)));
    });
    assert.strictEqual(process.env.VALIDATOR_SHARE_ENV, 'set-by-worker',
      `parent saw: ${process.env.VALIDATOR_SHARE_ENV}`);
    console.log('OK share-env', process.env.VALIDATOR_SHARE_ENV);
  })().catch((err) => {
    console.error(err && err.stack || err);
    process.exit(1);
  });
}
JS

node "$tmpdir/run.js" >"$tmpdir/out"

validator_assert_contains "$tmpdir/out" 'OK share-env set-by-worker'
