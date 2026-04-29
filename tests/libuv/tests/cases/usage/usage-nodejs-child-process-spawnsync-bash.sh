#!/usr/bin/env bash
# @testcase: usage-nodejs-child-process-spawnsync-bash
# @title: Node.js child process spawnSync
# @description: Runs a synchronous subprocess with child_process.spawnSync and verifies the captured stdout payload.
# @timeout: 180
# @tags: usage, nodejs, child-process
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-nodejs-child-process-spawnsync-bash"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

node >"$tmpdir/out" <<'JS'
const { spawnSync } = require('child_process');
const result = spawnSync('bash', ['-lc', 'printf spawn-sync-ok']);
if (result.status !== 0) throw new Error('spawnSync failed');
console.log(result.stdout.toString('utf8'));
JS
validator_assert_contains "$tmpdir/out" 'spawn-sync-ok'
