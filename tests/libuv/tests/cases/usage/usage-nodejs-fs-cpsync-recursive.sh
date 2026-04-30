#!/usr/bin/env bash
# @testcase: usage-nodejs-fs-cpsync-recursive
# @title: Node.js fs.cpSync recursive copy
# @description: Builds a nested directory tree and copies it with fs.cpSync recursive:true, verifying every file lands at the expected destination path with matching contents.
# @timeout: 180
# @tags: usage, nodejs, fs
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/run.js" <<'JS'
const assert = require('assert');
const fs = require('fs');
const path = require('path');

const tmpdir = process.argv[2];
const src = path.join(tmpdir, 'src');
const dst = path.join(tmpdir, 'dst');

fs.mkdirSync(path.join(src, 'sub', 'nested'), { recursive: true });
fs.writeFileSync(path.join(src, 'top.txt'), 'top payload\n');
fs.writeFileSync(path.join(src, 'sub', 'middle.txt'), 'middle payload\n');
fs.writeFileSync(path.join(src, 'sub', 'nested', 'leaf.txt'), 'leaf payload\n');

fs.cpSync(src, dst, { recursive: true });

const top = fs.readFileSync(path.join(dst, 'top.txt'), 'utf8');
const middle = fs.readFileSync(path.join(dst, 'sub', 'middle.txt'), 'utf8');
const leaf = fs.readFileSync(path.join(dst, 'sub', 'nested', 'leaf.txt'), 'utf8');

assert.strictEqual(top, 'top payload\n');
assert.strictEqual(middle, 'middle payload\n');
assert.strictEqual(leaf, 'leaf payload\n');

const dirStat = fs.statSync(path.join(dst, 'sub', 'nested'));
assert.ok(dirStat.isDirectory(), 'nested dir copied');

console.log('OK cpsync top=%d middle=%d leaf=%d', top.length, middle.length, leaf.length);
JS

node "$tmpdir/run.js" "$tmpdir" >"$tmpdir/out"

validator_assert_contains "$tmpdir/out" 'OK cpsync top=12 middle=15 leaf=13'
