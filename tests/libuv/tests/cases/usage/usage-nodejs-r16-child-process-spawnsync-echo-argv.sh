#!/usr/bin/env bash
# @testcase: usage-nodejs-r16-child-process-spawnsync-echo-argv
# @title: Node.js child_process.spawnSync invokes printf to echo a structured argv into stdout
# @description: Calls child_process.spawnSync('printf', ['%s|%s|%s', 'a', 'b', 'c']), asserts the exit status is 0, asserts stdout decoded as utf8 equals 'a|b|c', and asserts stderr is empty — exercising Node.js's libuv process spawn surface.
# @timeout: 60
# @tags: usage, nodejs, child_process, spawn
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/script.js" <<'JS'
const assert = require('assert');
const { spawnSync } = require('child_process');
const r = spawnSync('printf', ['%s|%s|%s', 'a', 'b', 'c']);
assert.strictEqual(r.status, 0, 'status=' + r.status);
assert.strictEqual(r.stdout.toString('utf8'), 'a|b|c');
assert.strictEqual(r.stderr.toString('utf8'), '');
console.log('OK spawnSync.argv');
JS

node "$tmpdir/script.js" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'OK spawnSync.argv'
