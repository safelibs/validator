#!/usr/bin/env bash
# @testcase: usage-nodejs-abort-controller-readfile
# @title: Node.js fs.promises.readFile aborts via AbortController
# @description: Aborts an fs.promises.readFile call before it resolves and verifies the rejection carries an AbortError code.
# @timeout: 120
# @tags: usage, event-loop, fs
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

node - "$tmpdir" <<'JS' >"$tmpdir/out"
const fsp = require('fs/promises');
const path = require('path');
const tmp = process.argv[2];
(async () => {
  const file = path.join(tmp, 'big.bin');
  await fsp.writeFile(file, Buffer.alloc(4 * 1024 * 1024, 1));
  const ac = new AbortController();
  queueMicrotask(() => ac.abort());
  try {
    await fsp.readFile(file, { signal: ac.signal });
    console.error('expected abort');
    process.exit(1);
  } catch (err) {
    if (err.name !== 'AbortError' && err.code !== 'ABORT_ERR') {
      console.error('unexpected error', err);
      process.exit(1);
    }
    console.log('OK aborted', err.name || err.code);
  }
})();
JS

validator_assert_contains "$tmpdir/out" 'OK aborted'
