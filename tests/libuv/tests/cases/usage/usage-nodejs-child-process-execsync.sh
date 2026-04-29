#!/usr/bin/env bash
# @testcase: usage-nodejs-child-process-execsync
# @title: Node.js child_process execSync
# @description: Runs a synchronous subprocess with execSync and verifies the captured output.
# @timeout: 180
# @tags: usage, nodejs, process
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-nodejs-child-process-execsync"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

node >"$tmpdir/out" <<'JS'
const { execSync } = require('child_process');
const value = execSync('printf execsync-ok').toString('utf8');
console.log(value);
JS
validator_assert_contains "$tmpdir/out" 'execsync-ok'
