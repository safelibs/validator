#!/usr/bin/env bash
# @testcase: usage-nodejs-r21-fs-promises-cp-recursive-tree
# @title: Node.js fs.promises.cp recursively copies a nested directory tree
# @description: Builds a source tree with two nested files, awaits fs.promises.cp(src, dst, { recursive: true }), and asserts both nested file contents at the destination match the source byte-for-byte, exercising libuv's recursive copy operation surfaced through Node fs.promises.
# @timeout: 60
# @tags: usage, fs, cp, recursive, nodejs, r21
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/s.js" <<JS
const assert = require('assert');
const fs = require('fs');
const fsp = require('fs/promises');
const path = require('path');

const base = process.argv[2];
const src = path.join(base, 'src');
const dst = path.join(base, 'dst');
fs.mkdirSync(path.join(src, 'a'), { recursive: true });
fs.mkdirSync(path.join(src, 'b'), { recursive: true });
fs.writeFileSync(path.join(src, 'a', 'one.txt'), 'aaaa');
fs.writeFileSync(path.join(src, 'b', 'two.txt'), 'bbbb');

(async () => {
  await fsp.cp(src, dst, { recursive: true });
  assert.strictEqual(fs.readFileSync(path.join(dst, 'a', 'one.txt'), 'utf8'), 'aaaa');
  assert.strictEqual(fs.readFileSync(path.join(dst, 'b', 'two.txt'), 'utf8'), 'bbbb');
  console.log('OK cp recursive');
})();
JS

node "$tmpdir/s.js" "$tmpdir" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'OK cp recursive'
