#!/usr/bin/env bash
# @testcase: usage-nodejs-r12-os-cpus-fields
# @title: Node.js os.cpus returns an array of CPU descriptors with positive speeds
# @description: Calls os.cpus and asserts the result is a non-empty array whose entries have a numeric speed and a times object with idle/user fields.
# @timeout: 60
# @tags: usage, os, nodejs
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/script.js" <<'JS'
const assert = require('assert');
const os = require('os');
const cpus = os.cpus();
assert.ok(Array.isArray(cpus), 'array');
assert.ok(cpus.length >= 1, 'len='+cpus.length);
const c = cpus[0];
assert.strictEqual(typeof c.model, 'string');
assert.strictEqual(typeof c.speed, 'number');
assert.ok(c.speed >= 0, 'speed='+c.speed);
assert.strictEqual(typeof c.times.idle, 'number');
assert.strictEqual(typeof c.times.user, 'number');
console.log('OK os.cpus');
JS

node "$tmpdir/script.js" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'OK os.cpus'
