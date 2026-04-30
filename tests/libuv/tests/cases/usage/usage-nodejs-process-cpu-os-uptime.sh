#!/usr/bin/env bash
# @testcase: usage-nodejs-process-cpu-os-uptime
# @title: Node.js process.cpuUsage and os.uptime sanity
# @description: Asserts process.cpuUsage diff is non-negative after busy work and os.uptime returns a positive number.
# @timeout: 180
# @tags: usage, process, os
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

node >"$tmpdir/out" <<'JS'
const assert = require('assert');
const os = require('os');

const start = process.cpuUsage();
let acc = 0;
for (let i = 0; i < 200000; i++) acc += Math.sqrt(i);
assert.ok(Number.isFinite(acc));

const diff = process.cpuUsage(start);
assert.strictEqual(typeof diff.user, 'number');
assert.strictEqual(typeof diff.system, 'number');
assert.ok(diff.user >= 0, 'user >= 0');
assert.ok(diff.system >= 0, 'system >= 0');
assert.ok(diff.user + diff.system > 0, 'cpu time advanced');

const up = os.uptime();
assert.strictEqual(typeof up, 'number');
assert.ok(up > 0 && Number.isFinite(up), 'os.uptime > 0');

console.log('OK cpu-os', 'cpuTotal>0', 'uptime>0');
JS

validator_assert_contains "$tmpdir/out" 'OK cpu-os cpuTotal>0 uptime>0'
