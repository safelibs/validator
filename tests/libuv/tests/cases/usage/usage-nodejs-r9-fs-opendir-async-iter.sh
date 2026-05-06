#!/usr/bin/env bash
# @testcase: usage-nodejs-r9-fs-opendir-async-iter
# @title: Node.js fs.opendir async iteration
# @description: Iterates a directory using fs.promises.opendir's async iterator and verifies the dirent set matches the seeded files.
# @timeout: 60
# @tags: usage, fs, nodejs
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir "$tmpdir/d"
printf 'a' >"$tmpdir/d/a.txt"
printf 'b' >"$tmpdir/d/b.txt"
printf 'c' >"$tmpdir/d/c.txt"

node - "$tmpdir/d" <<'JS'
const fs = require('fs').promises;
const assert = require('assert');
(async () => {
  const dir = await fs.opendir(process.argv[2]);
  const names = [];
  for await (const ent of dir) {
    names.push(ent.name);
    assert.equal(ent.isFile(), true);
  }
  names.sort();
  assert.deepStrictEqual(names, ['a.txt', 'b.txt', 'c.txt']);
})().catch(e => { console.error(e); process.exit(1); });
JS
