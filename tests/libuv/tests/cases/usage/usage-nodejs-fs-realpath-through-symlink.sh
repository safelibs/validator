#!/usr/bin/env bash
# @testcase: usage-nodejs-fs-realpath-through-symlink
# @title: Node.js fs.realpath resolves through a symlink
# @description: Creates a directory symlink and asserts fs.promises.realpath resolves a path through it to the canonical target.
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
  const realDir = path.join(root, 'real');
  const linkDir = path.join(root, 'link');
  await fsp.mkdir(realDir);
  const realFile = path.join(realDir, 'data.txt');
  await fsp.writeFile(realFile, 'realpath-symlink payload\n');
  await fsp.symlink(realDir, linkDir, 'dir');

  const linkedFile = path.join(linkDir, 'data.txt');
  assert.strictEqual(fs.readFileSync(linkedFile, 'utf8'), 'realpath-symlink payload\n');

  const resolved = await fsp.realpath(linkedFile);
  const expected = await fsp.realpath(realFile);
  assert.strictEqual(resolved, expected);
  assert.ok(resolved.endsWith(path.join('real', 'data.txt')), 'resolved=' + resolved);

  console.log('OK realpath', path.relative(root, resolved));
})().catch((e) => { console.error(e); process.exit(1); });
JS

validator_assert_contains "$tmpdir/out" 'OK realpath real/data.txt'
