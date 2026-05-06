#!/usr/bin/env bash
# @testcase: usage-nodejs-r10-worker-transferlist-arraybuffer
# @title: Node.js worker postMessage transferList detaches ArrayBuffer
# @description: Posts an ArrayBuffer to a worker via the transferList, has the worker echo back its byteLength, and verifies the parent-side ArrayBuffer is detached (byteLength == 0) after transfer.
# @timeout: 60
# @tags: usage, worker, nodejs
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

node - <<'JS'
const { Worker, isMainThread, parentPort } = require('worker_threads');
const assert = require('assert');

if (isMainThread) {
  const buf = new ArrayBuffer(2048);
  // Fill with a pattern so the worker can checksum it.
  new Uint8Array(buf).fill(0x5a);
  const w = new Worker(__filename);
  w.once('message', (msg) => {
    assert.strictEqual(msg.byteLength, 2048);
    assert.strictEqual(msg.firstByte, 0x5a);
    // After transfer, the parent-side buffer must be detached.
    assert.strictEqual(buf.byteLength, 0, 'parent ArrayBuffer should be detached after transfer');
    w.terminate();
  });
  w.on('error', (e) => { throw e; });
  w.postMessage(buf, [buf]);
} else {
  parentPort.once('message', (b) => {
    const view = new Uint8Array(b);
    parentPort.postMessage({ byteLength: b.byteLength, firstByte: view[0] });
  });
}
JS
