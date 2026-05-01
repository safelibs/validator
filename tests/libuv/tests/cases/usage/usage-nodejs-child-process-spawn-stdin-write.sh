#!/usr/bin/env bash
# @testcase: usage-nodejs-child-process-spawn-stdin-write
# @title: Node.js child_process.spawn pipe stdin write
# @description: Spawns /usr/bin/wc with piped stdio, writes a payload to stdin and asserts the byte count returned on stdout matches.
# @timeout: 120
# @tags: usage, event-loop, child-process
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

node >"$tmpdir/out" <<'JS'
const { spawn } = require('child_process');
const child = spawn('/usr/bin/wc', ['-c'], { stdio: ['pipe', 'pipe', 'pipe'] });
let out = '';
child.stdout.setEncoding('utf8');
child.stdout.on('data', (c) => { out += c; });
child.on('error', (e) => { console.error(e); process.exit(1); });
child.on('close', (code) => {
  if (code !== 0) { console.error('exit', code); process.exit(1); }
  const n = parseInt(out.trim(), 10);
  if (n !== 11) { console.error('unexpected count', out); process.exit(1); }
  console.log('OK wc-stdin', n);
});
child.stdin.end('hello world');
JS

validator_assert_contains "$tmpdir/out" 'OK wc-stdin 11'
