#!/usr/bin/env bash
# @testcase: usage-nodejs-r18-fs-promises-copyfile-roundtrip
# @title: Node.js fs.promises.copyFile duplicates a file with byte-identical contents
# @description: Writes a deterministic 256-byte payload to a source path via fs.promises.writeFile, calls fs.promises.copyFile to copy it to a sibling destination, and asserts both source and destination still exist and have byte-identical contents equal to the original payload, exercising libuv-backed copy_file primitives.
# @timeout: 60
# @tags: usage, nodejs, fs, copyfile, r18
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/script.js" <<JS
const assert = require('assert');
const fsp = require('fs/promises');
(async () => {
  const src = '$tmpdir/src.bin';
  const dst = '$tmpdir/dst.bin';
  const buf = Buffer.alloc(256);
  for (let i = 0; i < buf.length; i++) buf[i] = (i * 3 + 1) & 0xff;
  await fsp.writeFile(src, buf);
  await fsp.copyFile(src, dst);
  const a = await fsp.readFile(src);
  const b = await fsp.readFile(dst);
  assert.deepStrictEqual(a, buf);
  assert.deepStrictEqual(b, buf);
  console.log('OK copyfile.len=' + b.length);
})().catch((e) => { console.error(e); process.exit(1); });
JS

node "$tmpdir/script.js" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'OK copyfile.len=256'
