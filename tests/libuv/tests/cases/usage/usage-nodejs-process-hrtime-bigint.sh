#!/usr/bin/env bash
# @testcase: usage-nodejs-process-hrtime-bigint
# @title: nodejs hrtime bigint monotonic
# @description: Reads two consecutive process.hrtime.bigint samples through Node and verifies the second value is not earlier than the first.
# @timeout: 180
# @tags: usage, nodejs, process
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-nodejs-process-hrtime-bigint"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

node >"$tmpdir/out" <<'JS'
const a = process.hrtime.bigint();
const b = process.hrtime.bigint();
if (b < a) throw new Error('non-monotonic hrtime');
console.log('monotonic-ok');
JS
validator_assert_contains "$tmpdir/out" 'monotonic-ok'
