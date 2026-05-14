#!/usr/bin/env bash
# @testcase: usage-nodejs-r18-child-process-spawn-exit-code-zero
# @title: Node.js child_process.spawn collects stdout and reports exit code 0 for /bin/true
# @description: Spawns /bin/echo via child_process.spawn with a fixed argv vector, accumulates the stdout data event chunks, awaits the close event, asserts the captured stdout (trimmed) equals "r18-spawn-token", and asserts the close event reports exit code 0, exercising libuv-backed process spawn + pipe wiring.
# @timeout: 60
# @tags: usage, nodejs, child_process, spawn, r18
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/script.js" <<'JS'
const assert = require('assert');
const { spawn } = require('child_process');

const child = spawn('/bin/echo', ['r18-spawn-token']);
const chunks = [];
child.stdout.on('data', (d) => chunks.push(d));
child.on('close', (code) => {
  assert.strictEqual(code, 0, 'exit=' + code);
  const out = Buffer.concat(chunks).toString('utf8').trim();
  assert.strictEqual(out, 'r18-spawn-token');
  console.log('OK spawn.out=' + out);
});
child.on('error', (e) => { console.error(e); process.exit(1); });
JS

node "$tmpdir/script.js" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'OK spawn.out=r18-spawn-token'
