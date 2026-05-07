#!/usr/bin/env bash
# @testcase: usage-nodejs-r12-fs-promises-mkdtemp-prefix
# @title: Node.js fs.promises.mkdtemp creates a unique directory under a prefix
# @description: Calls fs.promises.mkdtemp with a prefix in a known parent and asserts the returned path starts with the prefix and exists as a directory.
# @timeout: 60
# @tags: usage, fs, promises, nodejs
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/script.js" <<JS
const assert = require('assert');
const fs = require('fs/promises');
const path = require('path');
const fsSync = require('fs');
(async () => {
  const prefix = path.join('$tmpdir', 'r12-');
  const created = await fs.mkdtemp(prefix);
  assert.ok(created.startsWith(prefix), created);
  const st = fsSync.statSync(created);
  assert.strictEqual(st.isDirectory(), true);
  console.log('OK fs.promises.mkdtemp');
})().catch((e) => { console.error(e); process.exit(1); });
JS

node "$tmpdir/script.js" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'OK fs.promises.mkdtemp'
