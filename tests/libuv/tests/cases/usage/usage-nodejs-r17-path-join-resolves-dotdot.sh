#!/usr/bin/env bash
# @testcase: usage-nodejs-r17-path-join-resolves-dotdot
# @title: Node.js path.join collapses .. segments to produce a normalized POSIX path
# @description: Calls path.posix.join('/a/b', '..', 'c', '.', 'd.txt') and asserts the result equals '/a/c/d.txt', exercising Node.js path normalization rules on top of the libuv runtime.
# @timeout: 60
# @tags: usage, nodejs, path, join, r17
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/script.js" <<'JS'
const assert = require('assert');
const path = require('path');
const joined = path.posix.join('/a/b', '..', 'c', '.', 'd.txt');
assert.strictEqual(joined, '/a/c/d.txt');
console.log('OK path.join=' + joined);
JS

node "$tmpdir/script.js" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'OK path.join=/a/c/d.txt'
