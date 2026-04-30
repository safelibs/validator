#!/usr/bin/env bash
# @testcase: usage-nodejs-worker-message-channel-pingpong
# @title: Node.js worker_threads MessageChannel ping pong
# @description: Hands a MessageChannel port to a worker thread and exchanges a ping pong message pair through it.
# @timeout: 180
# @tags: usage, event-loop, worker
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

node >"$tmpdir/out" <<'JS'
const assert = require('assert');
const { Worker, MessageChannel } = require('worker_threads');

const code = `
  const { parentPort, workerData } = require('worker_threads');
  const port = workerData.port;
  port.on('message', (msg) => {
    if (msg !== 'ping') throw new Error('unexpected ' + msg);
    port.postMessage('pong');
    port.close();
    parentPort.postMessage('done');
  });
`;

const { port1, port2 } = new MessageChannel();
const worker = new Worker(code, { eval: true, workerData: { port: port2 }, transferList: [port2] });

let received = '';
port1.on('message', (msg) => { received = msg; });

worker.on('message', (msg) => {
  assert.strictEqual(msg, 'done');
  assert.strictEqual(received, 'pong');
  port1.close();
  worker.terminate();
  console.log('OK pingpong', received);
});
worker.on('error', (e) => { throw e; });

port1.postMessage('ping');
JS

validator_assert_contains "$tmpdir/out" 'OK pingpong pong'
