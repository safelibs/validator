#!/usr/bin/env bash
# @testcase: usage-nodejs-r20-os-eol-is-newline-on-linux
# @title: Node.js os.EOL is the single newline character on a Linux host
# @description: Reads the os.EOL property and asserts it is exactly the one-character string '\n' (LF), confirming Node's libuv-backed OS-line-terminator reflects Ubuntu 24.04 POSIX conventions.
# @timeout: 60
# @tags: usage, nodejs, os, eol, r20
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/script.js" <<'JS'
const assert = require('assert');
const os = require('os');
assert.strictEqual(os.EOL, '\n');
assert.strictEqual(os.EOL.length, 1);
console.log('OK os.EOL=LF');
JS

node "$tmpdir/script.js" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'OK os.EOL=LF'
