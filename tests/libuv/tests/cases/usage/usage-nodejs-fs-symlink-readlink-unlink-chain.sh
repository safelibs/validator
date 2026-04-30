#!/usr/bin/env bash
# @testcase: usage-nodejs-fs-symlink-readlink-unlink-chain
# @title: Node.js fs symlink readlink unlink chain
# @description: Creates a symlink with Node.js fs.symlink, reads it back with fs.readlink, then removes it with fs.unlink and verifies it is gone.
# @timeout: 120
# @tags: usage, nodejs, fs
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-nodejs-fs-symlink-readlink-unlink-chain"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/script.js" <<'JS'
const fsp = require('fs/promises');
const fs = require('fs');
const path = require('path');
(async () => {
  const tmpdir = process.argv[2];
  const target = path.join(tmpdir, 'chain-target.txt');
  const link = path.join(tmpdir, 'chain-link.txt');
  await fsp.writeFile(target, 'chain payload\n');
  await fsp.symlink(target, link);
  const resolved = await fsp.readlink(link);
  if (path.basename(resolved) !== 'chain-target.txt') {
    throw new Error('readlink=' + resolved);
  }
  await fsp.unlink(link);
  if (fs.existsSync(link)) throw new Error('link still exists');
  if (!fs.existsSync(target)) throw new Error('target was removed');
  console.log('symlink-chain ok ' + path.basename(resolved));
})().catch((err) => { console.error(err && err.stack || err); process.exit(1); });
JS

node "$tmpdir/script.js" "$tmpdir" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'symlink-chain ok chain-target.txt'
