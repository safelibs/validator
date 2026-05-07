#!/usr/bin/env bash
# @testcase: usage-nodejs-r15-path-resolve-absolute
# @title: Node.js path.resolve produces an absolute path from compound segments
# @description: Calls path.resolve('/abs', 'sub', '..', 'final') and asserts the result equals '/abs/final', confirming '..' segments collapse and the result is anchored at the leading absolute prefix.
# @timeout: 60
# @tags: usage, path, nodejs
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/script.js" <<'JS'
const assert = require('assert');
const path = require('path');
const r = path.resolve('/abs', 'sub', '..', 'final');
assert.strictEqual(r, '/abs/final');
assert.ok(path.isAbsolute(r));
console.log('OK path.resolve');
JS

node "$tmpdir/script.js" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'OK path.resolve'
