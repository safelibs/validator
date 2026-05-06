#!/usr/bin/env bash
# @testcase: usage-nodejs-r9-fs-promises-rm-recursive
# @title: Node.js fs.promises.rm recursive
# @description: Builds a nested directory tree and removes it via fs.promises.rm with recursive:true, then asserts the path no longer exists.
# @timeout: 60
# @tags: usage, fs, nodejs
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/tree/a/b/c"
printf 'leaf\n' >"$tmpdir/tree/a/b/c/leaf.txt"
printf 'sib\n' >"$tmpdir/tree/a/sibling.txt"

node - "$tmpdir/tree" <<'JS'
const fs = require('fs').promises;
const assert = require('assert');
(async () => {
  const root = process.argv[2];
  await fs.rm(root, { recursive: true });
  let missing = false;
  try { await fs.stat(root); } catch (e) { missing = e.code === 'ENOENT'; }
  assert.equal(missing, true);
})().catch(e => { console.error(e); process.exit(1); });
JS
