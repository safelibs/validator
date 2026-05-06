#!/usr/bin/env bash
# @testcase: usage-nodejs-r11-tty-isatty-pipe-false
# @title: Node.js tty.isatty returns false for piped stdin and unknown fds
# @description: Pipes empty stdin into node and asserts tty.isatty(0) is false, plus asserts a clearly-unbound fd 99 also reports false.
# @timeout: 60
# @tags: usage, tty, nodejs
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/script.js" <<'JS'
const assert = require('assert');
const tty = require('tty');
assert.strictEqual(tty.isatty(0), false);
assert.strictEqual(tty.isatty(99), false);
console.log('OK tty.isatty');
JS

echo | node "$tmpdir/script.js" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'OK tty.isatty'
