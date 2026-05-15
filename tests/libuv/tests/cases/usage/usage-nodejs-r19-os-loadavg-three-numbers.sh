#!/usr/bin/env bash
# @testcase: usage-nodejs-r19-os-loadavg-three-numbers
# @title: Node.js os.loadavg returns an array of three finite non-negative numbers
# @description: Calls os.loadavg(), asserts the result is an Array of length exactly 3, asserts each entry is a finite Number, asserts each entry is >= 0, and asserts os.uptime() returns a finite positive Number, exercising the libuv-backed OS-level system metric surface on Linux.
# @timeout: 60
# @tags: usage, nodejs, os, loadavg, r19
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/script.js" <<'JS'
const assert = require('assert');
const os = require('os');
const la = os.loadavg();
assert.ok(Array.isArray(la));
assert.strictEqual(la.length, 3);
for (const v of la) {
  assert.strictEqual(typeof v, 'number');
  assert.ok(Number.isFinite(v));
  assert.ok(v >= 0, 'negative load: ' + v);
}
const up = os.uptime();
assert.ok(Number.isFinite(up) && up > 0, 'uptime: ' + up);
console.log('OK loadavg=' + la.join(','));
JS

node "$tmpdir/script.js" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'OK loadavg='
