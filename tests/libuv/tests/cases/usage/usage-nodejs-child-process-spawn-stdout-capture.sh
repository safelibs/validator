#!/usr/bin/env bash
# @testcase: usage-nodejs-child-process-spawn-stdout-capture
# @title: Node.js child_process.spawn stdout capture
# @description: Spawns /bin/echo with an argument and asserts the stdout chunks concatenate to the expected payload with exit code zero.
# @timeout: 180
# @tags: usage, event-loop, process
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

node >"$tmpdir/out" <<'JS'
const assert = require('assert');
const { spawn } = require('child_process');

const child = spawn('/bin/echo', ['spawn-capture-payload']);
let stdout = '';
let stderr = '';
child.stdout.setEncoding('utf8');
child.stderr.setEncoding('utf8');
child.stdout.on('data', (c) => { stdout += c; });
child.stderr.on('data', (c) => { stderr += c; });
child.on('error', (e) => { throw e; });
child.on('close', (code, signal) => {
  assert.strictEqual(code, 0);
  assert.strictEqual(signal, null);
  assert.strictEqual(stderr, '');
  assert.strictEqual(stdout, 'spawn-capture-payload\n');
  console.log('OK spawn', stdout.trim());
});
JS

validator_assert_contains "$tmpdir/out" 'OK spawn spawn-capture-payload'
