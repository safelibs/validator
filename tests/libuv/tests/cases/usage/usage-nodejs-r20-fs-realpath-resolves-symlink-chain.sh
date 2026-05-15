#!/usr/bin/env bash
# @testcase: usage-nodejs-r20-fs-realpath-resolves-symlink-chain
# @title: Node.js fs.realpathSync follows a symlink chain to the canonical target
# @description: Creates a regular file 'target', a symlink 'link1' -> 'target', and a symlink 'link2' -> 'link1', calls fs.realpathSync('link2'), and asserts the returned path string ends with '/target', confirming the libuv-backed realpath syscall resolves a two-hop symlink chain to the canonical filesystem path.
# @timeout: 60
# @tags: usage, nodejs, fs, realpath, symlink, r20
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

echo "target body" >"$tmpdir/target"
ln -s "$tmpdir/target" "$tmpdir/link1"
ln -s "$tmpdir/link1" "$tmpdir/link2"

cat >"$tmpdir/script.js" <<'JS'
const assert = require('assert');
const fs = require('fs');
const link2 = process.argv[2];
const resolved = fs.realpathSync(link2);
assert.ok(resolved.endsWith('/target'), 'resolved=' + resolved);
console.log('OK realpath=' + resolved);
JS

node "$tmpdir/script.js" "$tmpdir/link2" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'OK realpath='
