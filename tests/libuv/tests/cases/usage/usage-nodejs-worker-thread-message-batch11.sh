#!/usr/bin/env bash
# @testcase: usage-nodejs-worker-thread-message-batch11
# @title: Node.js worker thread message
# @description: Passes a message from a Node.js worker thread to the parent event loop.
# @timeout: 180
# @tags: usage, nodejs, libuv
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-nodejs-worker-thread-message-batch11"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

node >"$tmpdir/out" <<'JS'
const { Worker } = require('worker_threads');
const worker = new Worker("const { parentPort } = require('worker_threads'); parentPort.postMessage('worker-ok');", { eval: true });
worker.on('message', msg => console.log(msg));
worker.on('error', err => { throw err; });
JS
validator_assert_contains "$tmpdir/out" 'worker-ok'
