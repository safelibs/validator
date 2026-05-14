#!/usr/bin/env bash
# @testcase: usage-nodejs-r18-fs-promises-chmod-then-stat-mode
# @title: Node.js fs.promises.chmod sets a file mode that stat reports back
# @description: Creates a temp file via fs.promises.writeFile, calls fs.promises.chmod with mode 0o600, then calls fs.promises.stat and asserts the low 9 bits of st.mode equal 0o600, confirming libuv-backed chmod/stat round-trip on Linux ext4-like filesystems.
# @timeout: 60
# @tags: usage, nodejs, fs, chmod, stat, r18
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/script.js" <<JS
const assert = require('assert');
const fsp = require('fs/promises');
(async () => {
  const path = '$tmpdir/f.bin';
  await fsp.writeFile(path, 'r18');
  await fsp.chmod(path, 0o600);
  const st = await fsp.stat(path);
  const bits = st.mode & 0o777;
  assert.strictEqual(bits, 0o600, 'bits=' + bits.toString(8));
  console.log('OK chmod.mode=' + bits.toString(8));
})().catch((e) => { console.error(e); process.exit(1); });
JS

node "$tmpdir/script.js" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'OK chmod.mode=600'
