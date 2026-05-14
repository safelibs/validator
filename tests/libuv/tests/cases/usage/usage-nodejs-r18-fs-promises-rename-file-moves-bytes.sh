#!/usr/bin/env bash
# @testcase: usage-nodejs-r18-fs-promises-rename-file-moves-bytes
# @title: Node.js fs.promises.rename moves a file, preserving its byte contents
# @description: Writes a fixed payload to a source path via fs.promises.writeFile, calls fs.promises.rename to move it to a sibling destination, asserts the source path is gone (ENOENT) and the destination exists with byte-identical contents to the original payload, exercising libuv-backed atomic rename semantics on the same filesystem.
# @timeout: 60
# @tags: usage, nodejs, fs, rename, r18
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/script.js" <<JS
const assert = require('assert');
const fsp = require('fs/promises');
const { constants } = require('fs');
(async () => {
  const src = '$tmpdir/src.bin';
  const dst = '$tmpdir/dst.bin';
  const payload = Buffer.from('r18 nodejs rename payload bytes', 'utf8');
  await fsp.writeFile(src, payload);
  await fsp.rename(src, dst);
  try {
    await fsp.access(src, constants.F_OK);
    throw new Error('source still exists');
  } catch (e) {
    assert.strictEqual(e.code, 'ENOENT');
  }
  const got = await fsp.readFile(dst);
  assert.deepStrictEqual(got, payload);
  console.log('OK rename.bytes=' + got.length);
})().catch((e) => { console.error(e); process.exit(1); });
JS

node "$tmpdir/script.js" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'OK rename.bytes=31'
