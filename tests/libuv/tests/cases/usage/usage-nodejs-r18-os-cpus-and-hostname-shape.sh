#!/usr/bin/env bash
# @testcase: usage-nodejs-r18-os-cpus-and-hostname-shape
# @title: Node.js os.cpus returns a non-empty array and os.hostname returns a non-empty string
# @description: Calls require('os').cpus(), asserts the return is an Array with length at least 1 and each element has a string "model" plus a numeric "speed", then calls os.hostname() and asserts the result is a non-empty string, exercising libuv-backed system introspection (uv_cpu_info / uv_os_gethostname).
# @timeout: 60
# @tags: usage, nodejs, os, cpus, hostname, r18
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/script.js" <<'JS'
const assert = require('assert');
const os = require('os');
const cpus = os.cpus();
assert.ok(Array.isArray(cpus), 'cpus not array');
assert.ok(cpus.length >= 1, 'cpus.length=' + cpus.length);
for (const c of cpus) {
  assert.strictEqual(typeof c.model, 'string');
  assert.strictEqual(typeof c.speed, 'number');
}
const hn = os.hostname();
assert.strictEqual(typeof hn, 'string');
assert.ok(hn.length > 0, 'hostname empty');
console.log('OK cpus=' + cpus.length + ' hostname.len=' + hn.length);
JS

node "$tmpdir/script.js" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'OK cpus='
