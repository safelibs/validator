#!/usr/bin/env bash
# @testcase: usage-nodejs-r10-fs-cpsync-filter-callback
# @title: Node.js fs.cpSync recursive copy with filter callback
# @description: Recursively copies a directory tree with fs.cpSync using a filter that excludes .skip files, then verifies only the non-skipped entries appear at the destination.
# @timeout: 30
# @tags: usage, fs, nodejs
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/src/sub"
printf 'keep' >"$tmpdir/src/keep.txt"
printf 'drop' >"$tmpdir/src/drop.skip"
printf 'sub-keep' >"$tmpdir/src/sub/inner.txt"

node - "$tmpdir/src" "$tmpdir/dst" <<'JS'
const fs = require('fs');
const path = require('path');
const assert = require('assert');

const [src, dst] = process.argv.slice(2);
fs.cpSync(src, dst, {
  recursive: true,
  filter: (s) => !s.endsWith('.skip'),
});

assert.strictEqual(fs.readFileSync(path.join(dst, 'keep.txt'), 'utf8'), 'keep');
assert.strictEqual(fs.readFileSync(path.join(dst, 'sub/inner.txt'), 'utf8'), 'sub-keep');
assert.strictEqual(fs.existsSync(path.join(dst, 'drop.skip')), false);
JS
