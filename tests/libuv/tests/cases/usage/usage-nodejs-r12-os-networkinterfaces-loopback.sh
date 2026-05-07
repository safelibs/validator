#!/usr/bin/env bash
# @testcase: usage-nodejs-r12-os-networkinterfaces-loopback
# @title: Node.js os.networkInterfaces reports the loopback IPv4 entry
# @description: Filters os.networkInterfaces for an IPv4 entry with internal=true and address 127.0.0.1, asserting at least one interface exposes loopback.
# @timeout: 60
# @tags: usage, os, network, nodejs
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/script.js" <<'JS'
const assert = require('assert');
const os = require('os');
const ifs = os.networkInterfaces();
let found = false;
for (const name of Object.keys(ifs)) {
  for (const entry of ifs[name] || []) {
    if (entry.family === 'IPv4' && entry.internal === true && entry.address === '127.0.0.1') {
      found = true;
    }
  }
}
assert.strictEqual(found, true);
console.log('OK os.networkInterfaces.loopback');
JS

node "$tmpdir/script.js" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'OK os.networkInterfaces.loopback'
