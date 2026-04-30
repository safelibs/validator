#!/usr/bin/env bash
# @testcase: usage-nodejs-child-process-execfile-capture
# @title: Node.js child_process.execFile captures stdout
# @description: Invokes /bin/echo via child_process.execFile and asserts the captured stdout equals the expected payload with a zero exit status.
# @timeout: 180
# @tags: usage, event-loop, process
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

node >"$tmpdir/out" <<'JS'
const assert = require('assert');
const { execFile } = require('child_process');

execFile('/bin/echo', ['execfile-capture-payload'], { encoding: 'utf8' }, (err, stdout, stderr) => {
  if (err) throw err;
  assert.strictEqual(stderr, '');
  assert.strictEqual(stdout, 'execfile-capture-payload\n');
  console.log('OK execfile', stdout.trim());
});
JS

validator_assert_contains "$tmpdir/out" 'OK execfile execfile-capture-payload'
