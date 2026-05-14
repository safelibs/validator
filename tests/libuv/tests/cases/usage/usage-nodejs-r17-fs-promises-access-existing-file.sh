#!/usr/bin/env bash
# @testcase: usage-nodejs-r17-fs-promises-access-existing-file
# @title: Node.js fs.promises.access resolves for an existing file and rejects for a missing path
# @description: Creates a temporary file, calls fs.promises.access with F_OK on the existing path (expects resolution), and calls fs.promises.access on a missing sibling path (expects rejection with ENOENT); asserts both expectations are met, confirming libuv-backed async stat surfacing.
# @timeout: 60
# @tags: usage, nodejs, fs, access, r17
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

: >"$tmpdir/present.txt"

cat >"$tmpdir/script.js" <<JS
const assert = require('assert');
const fsp = require('fs/promises');
const { constants } = require('fs');
(async () => {
  await fsp.access('$tmpdir/present.txt', constants.F_OK);
  try {
    await fsp.access('$tmpdir/missing.txt', constants.F_OK);
    throw new Error('access on missing did not throw');
  } catch (e) {
    assert.strictEqual(e.code, 'ENOENT', 'unexpected error code: ' + e.code);
  }
  console.log('OK access.both');
})().catch((e) => { console.error(e); process.exit(1); });
JS

node "$tmpdir/script.js" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'OK access.both'
