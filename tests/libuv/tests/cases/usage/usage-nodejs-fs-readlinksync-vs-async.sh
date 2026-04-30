#!/usr/bin/env bash
# @testcase: usage-nodejs-fs-readlinksync-vs-async
# @title: Node.js fs.readlinkSync vs fs.readlink async parity
# @description: Creates a symlink and verifies fs.readlinkSync and the async fs.readlink callback API both return the same target string.
# @timeout: 180
# @tags: usage, nodejs, fs
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/run.js" <<'JS'
const assert = require('assert');
const fs = require('fs');
const path = require('path');

const tmpdir = process.argv[2];
const target = path.join(tmpdir, 'target.txt');
const link = path.join(tmpdir, 'link');

fs.writeFileSync(target, 'readlink parity\n');
fs.symlinkSync(target, link);

const sync = fs.readlinkSync(link);
assert.strictEqual(sync, target);

fs.readlink(link, (err, async) => {
  if (err) {
    console.error(err.stack || err);
    process.exit(1);
  }
  assert.strictEqual(async, target);
  assert.strictEqual(sync, async);
  console.log('OK readlink sync=async len=%d', sync.length);
});
JS

node "$tmpdir/run.js" "$tmpdir" >"$tmpdir/out"

validator_assert_contains "$tmpdir/out" 'OK readlink sync=async len='
