#!/usr/bin/env bash
# @testcase: usage-nodejs-r14-fs-promises-utimes-roundtrip
# @title: Node.js fs.promises.utimes sets atime and mtime to deterministic epoch seconds
# @description: Writes a probe file, calls fs.promises.utimes with explicit atime=1700000000 and mtime=1600000000 epoch-second values, then awaits fs.promises.stat and asserts the returned atimeMs and mtimeMs match the requested seconds (within sub-second tolerance for filesystem timestamp resolution).
# @timeout: 60
# @tags: usage, fs, nodejs
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'utimes\n' >"$tmpdir/probe.txt"

cat >"$tmpdir/script.js" <<'JS'
const assert = require('assert');
const fsp = require('fs/promises');
(async () => {
  const dir = process.argv[2];
  const path = dir + '/probe.txt';
  const atime = 1700000000;
  const mtime = 1600000000;
  await fsp.utimes(path, atime, mtime);
  const st = await fsp.stat(path);
  // Allow up to 2s tolerance for filesystems with coarse timestamp granularity.
  assert.ok(Math.abs(st.atimeMs - atime * 1000) < 2000, 'atime=' + st.atimeMs);
  assert.ok(Math.abs(st.mtimeMs - mtime * 1000) < 2000, 'mtime=' + st.mtimeMs);
  console.log('OK fs.promises.utimes');
})().catch(e => { console.error(e); process.exit(1); });
JS

node "$tmpdir/script.js" "$tmpdir" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'OK fs.promises.utimes'
