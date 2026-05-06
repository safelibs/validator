#!/usr/bin/env bash
# @testcase: usage-nodejs-r9-process-cpu-usage-delta
# @title: Node.js process.cpuUsage delta is non-negative
# @description: Calls process.cpuUsage twice with a busy loop in between and verifies the delta has non-negative user and system fields.
# @timeout: 60
# @tags: usage, process, nodejs
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

node - <<'JS'
const assert = require('assert');
const start = process.cpuUsage();
let x = 0;
for (let i = 0; i < 5_000_000; i++) x += i;
const delta = process.cpuUsage(start);
assert.ok(typeof delta.user === 'number', 'user is number');
assert.ok(typeof delta.system === 'number', 'system is number');
assert.ok(delta.user >= 0, `user ${delta.user}`);
assert.ok(delta.system >= 0, `system ${delta.system}`);
// Hint to optimiser to keep the loop alive.
if (x === Infinity) console.log(x);
JS
