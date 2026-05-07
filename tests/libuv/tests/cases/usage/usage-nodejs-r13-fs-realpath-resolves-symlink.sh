#!/usr/bin/env bash
# @testcase: usage-nodejs-r13-fs-realpath-resolves-symlink
# @title: Node.js fs.promises.realpath resolves a symlink to its target file
# @description: Creates a target file and a relative symlink, calls fs.promises.realpath on the symlink, and asserts the resolved absolute path equals the realpath of the target.
# @timeout: 60
# @tags: usage, fs, symlink, nodejs
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

real_root=$(realpath "$tmpdir")
printf 'realpath payload\n' >"$real_root/target.txt"
ln -s target.txt "$real_root/link.txt"

cat >"$real_root/script.js" <<JS
const assert = require('assert');
const fsp = require('fs/promises');
(async () => {
  const resolved = await fsp.realpath('$real_root/link.txt');
  assert.strictEqual(resolved, '$real_root/target.txt');
  console.log('OK fs.realpath');
})().catch((e) => { console.error(e); process.exit(1); });
JS

node "$real_root/script.js" >"$real_root/out"
validator_assert_contains "$real_root/out" 'OK fs.realpath'
