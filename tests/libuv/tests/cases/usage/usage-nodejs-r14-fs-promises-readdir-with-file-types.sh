#!/usr/bin/env bash
# @testcase: usage-nodejs-r14-fs-promises-readdir-with-file-types
# @title: Node.js fs.promises.readdir with withFileTypes returns Dirent entries
# @description: Creates a temp directory with one regular file and one subdirectory, then awaits fs.promises.readdir with withFileTypes:true and asserts the returned Dirent entries report the correct names and isFile/isDirectory classification.
# @timeout: 60
# @tags: usage, fs, nodejs
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir "$tmpdir/sub"
printf 'hello\n' >"$tmpdir/file.txt"

cat >"$tmpdir/script.js" <<'JS'
const assert = require('assert');
const fsp = require('fs/promises');
(async () => {
  const dir = process.argv[2];
  const entries = await fsp.readdir(dir, { withFileTypes: true });
  assert.strictEqual(entries.length, 2, 'len=' + entries.length);
  const byName = Object.fromEntries(entries.map(e => [e.name, e]));
  assert.ok(byName['file.txt'], 'file.txt missing');
  assert.ok(byName['sub'], 'sub missing');
  assert.strictEqual(byName['file.txt'].isFile(), true);
  assert.strictEqual(byName['file.txt'].isDirectory(), false);
  assert.strictEqual(byName['sub'].isDirectory(), true);
  assert.strictEqual(byName['sub'].isFile(), false);
  console.log('OK fs.promises.readdir withFileTypes');
})().catch(e => { console.error(e); process.exit(1); });
JS

node "$tmpdir/script.js" "$tmpdir" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'OK fs.promises.readdir withFileTypes'
