#!/usr/bin/env bash
# @testcase: usage-nodejs-net-isipv4-isipv6
# @title: Node.js net.isIPv4 and net.isIPv6 classification
# @description: Checks net.isIPv4 and net.isIPv6 return the expected booleans for a representative set of IPv4 addresses, IPv6 addresses, and non-addresses.
# @timeout: 60
# @tags: usage, nodejs, net
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/run.js" <<'JS'
const assert = require('assert');
const net = require('net');

assert.strictEqual(net.isIPv4('127.0.0.1'), true);
assert.strictEqual(net.isIPv4('10.0.0.1'), true);
assert.strictEqual(net.isIPv4('::1'), false);
assert.strictEqual(net.isIPv4('not-an-ip'), false);
assert.strictEqual(net.isIPv4(''), false);

assert.strictEqual(net.isIPv6('::1'), true);
assert.strictEqual(net.isIPv6('fe80::1'), true);
assert.strictEqual(net.isIPv6('2001:db8::1'), true);
assert.strictEqual(net.isIPv6('127.0.0.1'), false);
assert.strictEqual(net.isIPv6(''), false);

assert.strictEqual(net.isIP('127.0.0.1'), 4);
assert.strictEqual(net.isIP('::1'), 6);
assert.strictEqual(net.isIP('garbage'), 0);

console.log('OK isipv4-isipv6 v4=true v6=true cross=false');
JS

node "$tmpdir/run.js" >"$tmpdir/out"

validator_assert_contains "$tmpdir/out" 'OK isipv4-isipv6 v4=true v6=true cross=false'
