#!/usr/bin/env bash
# @testcase: usage-nodejs-r20-path-extname-and-basename
# @title: Node.js path.extname and path.basename split a filename into name and extension
# @description: Calls path.extname('/a/b/c.tar.gz') and asserts the return is '.gz' (only the last extension), calls path.basename('/a/b/file.txt') and asserts the return is 'file.txt', calls path.basename('/a/b/file.txt', '.txt') and asserts the return is 'file', confirming Node's documented POSIX path semantics.
# @timeout: 60
# @tags: usage, nodejs, path, basename, extname, r20
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/script.js" <<'JS'
const assert = require('assert');
const path = require('path');
assert.strictEqual(path.extname('/a/b/c.tar.gz'), '.gz');
assert.strictEqual(path.basename('/a/b/file.txt'), 'file.txt');
assert.strictEqual(path.basename('/a/b/file.txt', '.txt'), 'file');
console.log('OK path');
JS

node "$tmpdir/script.js" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'OK path'
