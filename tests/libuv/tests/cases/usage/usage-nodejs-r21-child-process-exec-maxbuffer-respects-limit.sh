#!/usr/bin/env bash
# @testcase: usage-nodejs-r21-child-process-exec-maxbuffer-respects-limit
# @title: Node.js child_process.exec aborts a child that exceeds maxBuffer
# @description: Spawns 'sh -c "yes | head -c 200000"' under child_process.exec with maxBuffer set to 1024 and asserts the callback fires with an Error whose .code equals 'ERR_CHILD_PROCESS_STDIO_MAXBUFFER', validating libuv-managed stdio buffering caps in Node's child_process API.
# @timeout: 60
# @tags: usage, child-process, maxbuffer, nodejs, r21
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/s.js" <<'JS'
const assert = require('assert');
const { exec } = require('child_process');

exec('yes | head -c 200000', { maxBuffer: 1024 }, (err, stdout, stderr) => {
  assert.ok(err, 'expected error, got none');
  assert.strictEqual(err.code, 'ERR_CHILD_PROCESS_STDIO_MAXBUFFER', 'err.code=' + err.code);
  console.log('OK maxbuffer code=' + err.code);
});
JS

node "$tmpdir/s.js" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'OK maxbuffer'
