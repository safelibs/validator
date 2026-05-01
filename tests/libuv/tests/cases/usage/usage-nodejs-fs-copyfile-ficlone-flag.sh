#!/usr/bin/env bash
# @testcase: usage-nodejs-fs-copyfile-ficlone-flag
# @title: Node.js fs.copyFile with COPYFILE_FICLONE flag
# @description: Copies a file using fs.promises.copyFile with the COPYFILE_FICLONE flag and asserts the destination contents match the source byte-for-byte.
# @timeout: 180
# @tags: usage, event-loop, fs
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

WORK_DIR="$tmpdir" node >"$tmpdir/out" <<'JS'
const assert = require('assert');
const fs = require('fs');
const fsp = require('fs/promises');
const path = require('path');

(async () => {
  const root = process.env.WORK_DIR;
  const src = path.join(root, 'src.bin');
  const dst = path.join(root, 'dst.bin');
  const payload = Buffer.from('ficlone-payload-' + 'x'.repeat(100));
  await fsp.writeFile(src, payload);

  await fsp.copyFile(src, dst, fs.constants.COPYFILE_FICLONE);

  const body = await fsp.readFile(dst);
  assert.ok(body.equals(payload), 'copy must equal source');
  assert.strictEqual(body.length, payload.length);

  console.log('OK ficlone', body.length);
})().catch((e) => { console.error(e); process.exit(1); });
JS

validator_assert_contains "$tmpdir/out" 'OK ficlone 116'
