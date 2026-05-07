#!/usr/bin/env bash
# @testcase: usage-nodejs-r12-child-process-spawn-stdout
# @title: Node.js child_process.spawn collects stdout from /bin/echo
# @description: Spawns /bin/echo with an argument, collects stdout, and asserts the buffer contains the expected token followed by a newline with exit code 0.
# @timeout: 60
# @tags: usage, child_process, nodejs
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/script.js" <<'JS'
const assert = require('assert');
const { spawn } = require('child_process');
const child = spawn('/bin/echo', ['r12-spawn-token']);
const chunks = [];
child.stdout.on('data', (c) => chunks.push(c));
child.on('close', (code) => {
  assert.strictEqual(code, 0);
  const out = Buffer.concat(chunks).toString();
  assert.strictEqual(out, 'r12-spawn-token\n');
  console.log('OK child_process.spawn');
});
child.on('error', (e) => { throw e; });
JS

node "$tmpdir/script.js" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'OK child_process.spawn'
