#!/usr/bin/env bash
# @testcase: usage-nodejs-path-normalize-backslash
# @title: Node.js posix path.normalize keeps backslash literal
# @description: Verifies path.posix.normalize treats backslash as a literal character on Linux and that path.normalize collapses redundant separators.
# @timeout: 180
# @tags: usage, nodejs, path
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

node >"$tmpdir/out" <<'JS'
const assert = require('assert');
const path = require('path');

// On linux, backslash is a normal character, not a separator.
const literal = path.posix.normalize('foo\\bar/baz');
assert.strictEqual(literal, 'foo\\bar/baz', 'literal: ' + literal);

// Redundant separators and dot segments collapse.
const collapsed = path.posix.normalize('/a//b/./c/../d');
assert.strictEqual(collapsed, '/a/b/d', 'collapsed: ' + collapsed);

// On linux path === path.posix, so default normalize behaves the same.
const def = path.normalize('/x///y');
assert.strictEqual(def, '/x/y', 'def: ' + def);

console.log('OK normalize', literal, collapsed, def);
JS

validator_assert_contains "$tmpdir/out" 'OK normalize foo\bar/baz /a/b/d /x/y'
