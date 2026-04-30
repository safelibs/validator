#!/usr/bin/env bash
# @testcase: usage-nodejs-fs-readfilesync-vs-async-equal
# @title: Node.js fs.readFileSync vs fs.readFile equal bytes
# @description: Reads the same file via fs.readFileSync and the async fs.readFile and verifies the returned buffers are byte-identical.
# @timeout: 180
# @tags: usage, nodejs, fs
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/run.js" <<'JS'
const assert = require('assert');
const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

const tmpdir = process.argv[2];
const file = path.join(tmpdir, 'payload.bin');
const payload = crypto.randomBytes(64 * 1024);
fs.writeFileSync(file, payload);

const sync = fs.readFileSync(file);
fs.readFile(file, (err, async) => {
  assert.ifError(err);
  assert.strictEqual(sync.length, payload.length);
  assert.strictEqual(async.length, payload.length);
  assert.ok(sync.equals(async), 'sync vs async mismatch');
  assert.ok(sync.equals(payload), 'sync vs payload mismatch');
  const digest = crypto.createHash('sha256').update(async).digest('hex');
  console.log('OK readfile-equal', sync.length, digest.slice(0, 12));
});
JS

node "$tmpdir/run.js" "$tmpdir" >"$tmpdir/out"

validator_assert_contains "$tmpdir/out" 'OK readfile-equal 65536 '
