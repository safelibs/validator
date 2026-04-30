#!/usr/bin/env bash
# @testcase: usage-nodejs-path-parse-absolute
# @title: Node.js path.parse on absolute path with path.format reconstruction
# @description: Parses an absolute POSIX path with path.parse, asserts every component, and verifies path.format reconstructs the original string from the parsed object.
# @timeout: 60
# @tags: usage, nodejs, path
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/run.js" <<'JS'
const assert = require('assert');
const path = require('path');

const input = '/usr/local/share/doc/readme.txt';
const parsed = path.posix.parse(input);

assert.strictEqual(parsed.root, '/');
assert.strictEqual(parsed.dir, '/usr/local/share/doc');
assert.strictEqual(parsed.base, 'readme.txt');
assert.strictEqual(parsed.name, 'readme');
assert.strictEqual(parsed.ext, '.txt');

const reformatted = path.posix.format(parsed);
assert.strictEqual(reformatted, input);

const noExt = path.posix.parse('/etc/hostname');
assert.strictEqual(noExt.root, '/');
assert.strictEqual(noExt.dir, '/etc');
assert.strictEqual(noExt.base, 'hostname');
assert.strictEqual(noExt.name, 'hostname');
assert.strictEqual(noExt.ext, '');
assert.strictEqual(path.posix.format(noExt), '/etc/hostname');

console.log('OK path-parse root=%s base=%s name=%s ext=%s', parsed.root, parsed.base, parsed.name, parsed.ext);
JS

node "$tmpdir/run.js" >"$tmpdir/out"

validator_assert_contains "$tmpdir/out" 'OK path-parse root=/ base=readme.txt name=readme ext=.txt'
