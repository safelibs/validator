#!/usr/bin/env bash
# @testcase: usage-nodejs-fs-cp-recursive
# @title: Node.js fs.cp recursive directory copy
# @description: Builds a small directory tree and copies it recursively with fs.promises.cp, then asserts files and contents at the destination.
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
  const root = process.env.WORK_DIR;
  const src = path.join(root, 'src');
  const dst = path.join(root, 'dst');
  await fsp.mkdir(path.join(src, 'sub'), { recursive: true });
  await fsp.writeFile(path.join(src, 'top.txt'), 'top-payload\n');
  await fsp.writeFile(path.join(src, 'sub', 'nested.txt'), 'nested-payload\n');

  await fsp.cp(src, dst, { recursive: true });

  const top = await fsp.readFile(path.join(dst, 'top.txt'), 'utf8');
  const nested = await fsp.readFile(path.join(dst, 'sub', 'nested.txt'), 'utf8');
  assert.strictEqual(top, 'top-payload\n');
  assert.strictEqual(nested, 'nested-payload\n');

  const entries = (await fsp.readdir(dst)).sort();
  assert.deepStrictEqual(entries, ['sub', 'top.txt']);

  console.log('OK cp', entries.join(','));
})().catch((e) => { console.error(e); process.exit(1); });
JS

validator_assert_contains "$tmpdir/out" 'OK cp sub,top.txt'
