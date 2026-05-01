#!/usr/bin/env bash
# @testcase: usage-nodejs-child-process-spawn-detached-false
# @title: Node.js child_process.spawn detached=false stdout capture
# @description: Spawns /bin/echo with detached set explicitly to false, captures stdout, and asserts a clean exit with the expected payload.
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

const child = spawn('/bin/echo', ['detached-false-payload'], { detached: false, stdio: ['ignore', 'pipe', 'pipe'] });
let body = '';
let errBody = '';
child.stdout.setEncoding('utf8');
child.stderr.setEncoding('utf8');
child.stdout.on('data', (c) => { body += c; });
child.stderr.on('data', (c) => { errBody += c; });
child.on('error', (e) => { console.error(e); process.exit(1); });
child.on('close', (code, signal) => {
  assert.strictEqual(code, 0);
  assert.strictEqual(signal, null);
  assert.strictEqual(errBody, '');
  assert.strictEqual(body, 'detached-false-payload\n');
  console.log('OK detached-false', body.trim());
});
JS

validator_assert_contains "$tmpdir/out" 'OK detached-false detached-false-payload'
