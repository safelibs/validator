#!/usr/bin/env bash
# @testcase: usage-nodejs-r14-fs-promises-access-constants
# @title: Node.js fs.promises.access reports F_OK and R_OK on a readable file
# @description: Writes a probe file and awaits fs.promises.access twice with fs.constants.F_OK and fs.constants.R_OK, asserting both calls resolve without throwing while access for a non-existent path is rejected with an Error whose code is 'ENOENT'.
# @timeout: 60
# @tags: usage, fs, nodejs
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'probe\n' >"$tmpdir/probe.txt"

cat >"$tmpdir/script.js" <<'JS'
const assert = require('assert');
const fs = require('fs');
const fsp = require('fs/promises');
(async () => {
  const dir = process.argv[2];
  await fsp.access(dir + '/probe.txt', fs.constants.F_OK);
  await fsp.access(dir + '/probe.txt', fs.constants.R_OK);
  let err;
  try {
    await fsp.access(dir + '/missing.txt', fs.constants.F_OK);
  } catch (e) { err = e; }
  assert.ok(err, 'expected access on missing path to throw');
  assert.strictEqual(err.code, 'ENOENT');
  console.log('OK fs.promises.access');
})().catch(e => { console.error(e); process.exit(1); });
JS

node "$tmpdir/script.js" "$tmpdir" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'OK fs.promises.access'
