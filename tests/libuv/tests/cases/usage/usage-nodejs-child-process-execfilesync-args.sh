#!/usr/bin/env bash
# @testcase: usage-nodejs-child-process-execfilesync-args
# @title: Node.js child_process.execFileSync passes argv array
# @description: Calls execFileSync with /bin/printf and a multi-element args array and asserts the returned buffer contains the joined payload.
# @timeout: 180
# @tags: usage, event-loop, process
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

node >"$tmpdir/out" <<'JS'
const assert = require('assert');
const { execFileSync } = require('child_process');

const buf = execFileSync('/bin/printf', ['%s-%s-%s\n', 'alpha', 'beta', 'gamma']);
assert.ok(Buffer.isBuffer(buf), 'execFileSync returns Buffer by default');
const text = buf.toString('utf8');
assert.strictEqual(text, 'alpha-beta-gamma\n');

const str = execFileSync('/bin/printf', ['%s', 'plain'], { encoding: 'utf8' });
assert.strictEqual(str, 'plain');

console.log('OK execfilesync', text.trim(), str);
JS

validator_assert_contains "$tmpdir/out" 'OK execfilesync alpha-beta-gamma plain'
