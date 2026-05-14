#!/usr/bin/env bash
# @testcase: usage-nodejs-r18-fs-promises-readdir-lists-files
# @title: Node.js fs.promises.readdir lists exactly the files created in a directory
# @description: Creates a fresh directory, writes three files with deterministic names via fs.promises.writeFile, calls fs.promises.readdir on the directory and asserts the returned array, when sorted, equals exactly ["a.txt", "b.txt", "c.txt"], exercising libuv-backed directory scan/readdir behavior.
# @timeout: 60
# @tags: usage, nodejs, fs, readdir, r18
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/script.js" <<JS
const assert = require('assert');
const fsp = require('fs/promises');
(async () => {
  const dir = '$tmpdir/dir';
  await fsp.mkdir(dir);
  await fsp.writeFile(dir + '/a.txt', 'A');
  await fsp.writeFile(dir + '/b.txt', 'B');
  await fsp.writeFile(dir + '/c.txt', 'C');
  const entries = await fsp.readdir(dir);
  entries.sort();
  assert.deepStrictEqual(entries, ['a.txt', 'b.txt', 'c.txt']);
  console.log('OK readdir.count=' + entries.length);
})().catch((e) => { console.error(e); process.exit(1); });
JS

node "$tmpdir/script.js" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'OK readdir.count=3'
