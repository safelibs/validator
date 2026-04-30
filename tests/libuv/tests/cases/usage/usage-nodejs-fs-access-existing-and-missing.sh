#!/usr/bin/env bash
# @testcase: usage-nodejs-fs-access-existing-and-missing
# @title: Node.js fs.access on existing and missing paths
# @description: Verifies fs.access resolves for an existing file and rejects with ENOENT for a missing one.
# @timeout: 180
# @tags: usage, event-loop, fs
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

WORK_DIR="$tmpdir" node >"$tmpdir/out" <<'JS'
const assert = require('assert');
const fsp = require('fs/promises');
const path = require('path');

(async () => {
  const dir = process.env.WORK_DIR;
  const existing = path.join(dir, 'present.txt');
  const missing = path.join(dir, 'absent.txt');
  await fsp.writeFile(existing, 'present\n');

  await fsp.access(existing);

  let captured = null;
  try {
    await fsp.access(missing);
  } catch (e) {
    captured = e;
  }
  assert.ok(captured, 'expected access on missing path to reject');
  assert.strictEqual(captured.code, 'ENOENT');

  console.log('OK access present=ok missing=ENOENT');
})().catch((e) => { console.error(e); process.exit(1); });
JS

validator_assert_contains "$tmpdir/out" 'OK access present=ok missing=ENOENT'
