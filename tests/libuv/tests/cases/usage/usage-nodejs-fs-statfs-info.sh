#!/usr/bin/env bash
# @testcase: usage-nodejs-fs-statfs-info
# @title: Node.js fs.statfs filesystem info
# @description: Calls Node.js fs.statfs against the temp directory and verifies the returned filesystem block totals look sane.
# @timeout: 120
# @tags: usage, nodejs, fs
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-nodejs-fs-statfs-info"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/script.js" <<'JS'
const fsp = require('fs/promises');
(async () => {
  const target = process.argv[2];
  const info = await fsp.statfs(target);
  if (typeof info.bsize !== 'number' || info.bsize <= 0) {
    throw new Error('bsize ' + info.bsize);
  }
  if (typeof info.blocks !== 'number' || info.blocks <= 0) {
    throw new Error('blocks ' + info.blocks);
  }
  if (typeof info.type !== 'number') {
    throw new Error('type ' + info.type);
  }
  console.log('statfs ok bsize=' + info.bsize);
})().catch((err) => { console.error(err && err.stack || err); process.exit(1); });
JS

node "$tmpdir/script.js" "$tmpdir" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'statfs ok'
