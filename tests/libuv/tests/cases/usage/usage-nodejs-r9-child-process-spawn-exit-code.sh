#!/usr/bin/env bash
# @testcase: usage-nodejs-r9-child-process-spawn-exit-code
# @title: Node.js child_process.spawn exit code propagation
# @description: Spawns /bin/sh -c 'exit 7' via child_process.spawn and verifies the exit event reports code 7 with null signal.
# @timeout: 60
# @tags: usage, child-process, nodejs
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

node - <<'JS'
const { spawn } = require('child_process');
const assert = require('assert');
const child = spawn('/bin/sh', ['-c', 'exit 7']);
child.on('exit', (code, signal) => {
  assert.equal(code, 7);
  assert.equal(signal, null);
});
child.on('error', e => { console.error(e); process.exit(1); });
JS
