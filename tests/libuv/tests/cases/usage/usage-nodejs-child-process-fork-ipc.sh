#!/usr/bin/env bash
# @testcase: usage-nodejs-child-process-fork-ipc
# @title: Node.js child_process.fork IPC message exchange
# @description: Forks a child Node.js process and exchanges a ping/pong message through the IPC channel, asserting the reply payload.
# @timeout: 180
# @tags: usage, event-loop, process, ipc
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/child.js" <<'CHILD'
process.on('message', (msg) => {
  if (msg && msg.kind === 'ping') {
    process.send({ kind: 'pong', echo: msg.value });
  }
});
CHILD

CHILD_SCRIPT="$tmpdir/child.js" node >"$tmpdir/out" <<'JS'
const assert = require('assert');
const { fork } = require('child_process');

const child = fork(process.env.CHILD_SCRIPT, [], { stdio: ['ignore', 'ignore', 'inherit', 'ipc'] });

const timer = setTimeout(() => {
  child.kill();
  console.error('timed out waiting for IPC pong');
  process.exit(1);
}, 5000);

child.on('message', (msg) => {
  clearTimeout(timer);
  assert.strictEqual(msg.kind, 'pong');
  assert.strictEqual(msg.echo, 'fork-ipc-payload');
  child.on('exit', (code) => {
    assert.strictEqual(code, 0);
    console.log('OK fork-ipc', msg.echo);
  });
  child.disconnect();
});

child.on('error', (e) => { throw e; });
child.send({ kind: 'ping', value: 'fork-ipc-payload' });
JS

validator_assert_contains "$tmpdir/out" 'OK fork-ipc fork-ipc-payload'
