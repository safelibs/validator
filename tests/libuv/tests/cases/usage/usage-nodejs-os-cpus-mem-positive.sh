#!/usr/bin/env bash
# @testcase: usage-nodejs-os-cpus-mem-positive
# @title: Node.js os.cpus and memory totals are positive
# @description: Verifies os.cpus() returns a non-empty array and os.totalmem and os.freemem return positive integers with totalmem >= freemem.
# @timeout: 120
# @tags: usage, os
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

node >"$tmpdir/out" <<'JS'
const assert = require('assert');
const os = require('os');

const cpus = os.cpus();
assert.ok(Array.isArray(cpus), 'cpus must be an array');
assert.ok(cpus.length >= 1, 'at least one cpu');
assert.strictEqual(typeof cpus[0].model, 'string');
assert.ok(cpus[0].speed > 0 || cpus[0].speed === 0, 'speed numeric');
assert.strictEqual(typeof cpus[0].times.user, 'number');

const total = os.totalmem();
const free = os.freemem();
assert.strictEqual(typeof total, 'number');
assert.strictEqual(typeof free, 'number');
assert.ok(total > 0, 'totalmem positive');
assert.ok(free > 0, 'freemem positive');
assert.ok(total >= free, 'totalmem >= freemem');

console.log('OK os-mem cpus>=1 total>free');
JS

validator_assert_contains "$tmpdir/out" 'OK os-mem cpus>=1 total>free'
