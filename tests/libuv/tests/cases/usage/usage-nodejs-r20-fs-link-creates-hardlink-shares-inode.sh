#!/usr/bin/env bash
# @testcase: usage-nodejs-r20-fs-link-creates-hardlink-shares-inode
# @title: Node.js fs.linkSync creates a hardlink whose inode matches the source
# @description: Writes a probe file 'src', calls fs.linkSync(src, dst) to create a hardlink, statSync both paths, and asserts the resulting ino fields are strictly equal (same inode), nlink for src is >= 2, and reading dst yields the same content as src, confirming libuv-backed link(2) shares the underlying inode.
# @timeout: 60
# @tags: usage, nodejs, fs, link, hardlink, r20
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/script.js" <<'JS'
const assert = require('assert');
const fs = require('fs');
const src = process.argv[2];
const dst = process.argv[3];
fs.writeFileSync(src, 'hardlink-r20');
fs.linkSync(src, dst);
const a = fs.statSync(src);
const b = fs.statSync(dst);
assert.strictEqual(a.ino, b.ino);
assert.ok(a.nlink >= 2, 'nlink=' + a.nlink);
assert.strictEqual(fs.readFileSync(dst, 'utf8'), 'hardlink-r20');
console.log('OK hardlink ino=' + a.ino);
JS

node "$tmpdir/script.js" "$tmpdir/src" "$tmpdir/dst" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'OK hardlink ino='
