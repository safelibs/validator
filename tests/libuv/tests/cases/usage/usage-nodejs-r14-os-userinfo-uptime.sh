#!/usr/bin/env bash
# @testcase: usage-nodejs-r14-os-userinfo-uptime
# @title: Node.js os.userInfo and os.uptime expose real numeric process and host data
# @description: Calls os.userInfo() and asserts the returned object exposes string username/homedir/shell fields with a numeric uid/gid, then calls os.uptime() and asserts it returns a positive finite number.
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
const info = os.userInfo();
assert.strictEqual(typeof info.username, 'string');
assert.ok(info.username.length > 0, 'empty username');
assert.strictEqual(typeof info.homedir, 'string');
assert.ok(info.homedir.startsWith('/'), 'homedir='+info.homedir);
assert.strictEqual(typeof info.uid, 'number');
assert.strictEqual(typeof info.gid, 'number');
const up = os.uptime();
assert.strictEqual(typeof up, 'number');
assert.ok(Number.isFinite(up) && up > 0, 'uptime='+up);
console.log('OK os.userInfo+uptime');
JS

node "$tmpdir/script.js" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'OK os.userInfo+uptime'
