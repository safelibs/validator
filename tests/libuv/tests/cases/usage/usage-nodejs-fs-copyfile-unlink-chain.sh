#!/usr/bin/env bash
# @testcase: usage-nodejs-fs-copyfile-unlink-chain
# @title: Node.js fs.copyFile then fs.unlink chain
# @description: Copies a file with fs.copyFile, verifies the copy contents match, then unlinks the copy and asserts removal via fs.access.
# @timeout: 180
# @tags: usage, nodejs, fs
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/run.js" <<'JS'
const assert = require('assert');
const fsp = require('fs/promises');
const path = require('path');

const tmpdir = process.argv[2];
const src = path.join(tmpdir, 'src.txt');
const dst = path.join(tmpdir, 'dst.txt');

(async () => {
  await fsp.writeFile(src, 'copyfile-unlink payload\n');
  await fsp.copyFile(src, dst);
  const body = await fsp.readFile(dst, 'utf8');
  assert.strictEqual(body, 'copyfile-unlink payload\n');

  await fsp.unlink(dst);
  let removed = false;
  try {
    await fsp.access(dst);
  } catch (err) {
    assert.strictEqual(err.code, 'ENOENT');
    removed = true;
  }
  assert.ok(removed, 'dst should be removed');

  const srcStat = await fsp.stat(src);
  assert.ok(srcStat.isFile(), 'src must remain');
  console.log('OK copyfile-unlink', srcStat.size);
})().catch((err) => {
  console.error(err && err.stack || err);
  process.exit(1);
});
JS

node "$tmpdir/run.js" "$tmpdir" >"$tmpdir/out"

validator_assert_contains "$tmpdir/out" 'OK copyfile-unlink 24'
