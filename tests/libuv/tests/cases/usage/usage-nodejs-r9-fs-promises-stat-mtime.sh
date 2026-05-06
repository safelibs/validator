#!/usr/bin/env bash
# @testcase: usage-nodejs-r9-fs-promises-stat-mtime
# @title: Node.js fs.promises.stat mtime via utimes
# @description: Sets a known mtime on a file via fs.promises.utimes and verifies fs.promises.stat reports the same value.
# @timeout: 60
# @tags: usage, fs, nodejs
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

f="$tmpdir/sample.txt"
printf 'hello\n' >"$f"

node - "$f" <<'JS'
const fs = require('fs').promises;
const assert = require('assert');
(async () => {
  const target = process.argv[2];
  const mtime = new Date(1700000000 * 1000);
  const atime = new Date(1700000100 * 1000);
  await fs.utimes(target, atime, mtime);
  const st = await fs.stat(target);
  assert.equal(Math.floor(st.mtimeMs / 1000), 1700000000);
  assert.equal(Math.floor(st.atimeMs / 1000), 1700000100);
})().catch(e => { console.error(e); process.exit(1); });
JS
