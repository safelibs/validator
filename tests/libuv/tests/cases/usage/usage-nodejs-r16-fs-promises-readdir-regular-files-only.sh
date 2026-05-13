#!/usr/bin/env bash
# @testcase: usage-nodejs-r16-fs-promises-readdir-regular-files-only
# @title: Node.js fs.promises.readdir enumerates only regular files created in a fresh tmp dir
# @description: Creates three regular files (alpha.txt, beta.txt, gamma.txt) in a fresh empty directory, calls fs.promises.readdir on it, and asserts the returned array sorted alphabetically equals exactly ['alpha.txt','beta.txt','gamma.txt'] — relying on regular files only to avoid dotfile/hidden-dir surfacing differences.
# @timeout: 60
# @tags: usage, nodejs, fs, readdir
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/d"
: >"$tmpdir/d/alpha.txt"
: >"$tmpdir/d/beta.txt"
: >"$tmpdir/d/gamma.txt"

cat >"$tmpdir/script.js" <<JS
const assert = require('assert');
const fsp = require('fs/promises');
(async () => {
  const names = (await fsp.readdir('$tmpdir/d')).sort();
  assert.deepStrictEqual(names, ['alpha.txt','beta.txt','gamma.txt']);
  console.log('OK readdir.files');
})().catch((e) => { console.error(e); process.exit(1); });
JS

node "$tmpdir/script.js" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'OK readdir.files'
