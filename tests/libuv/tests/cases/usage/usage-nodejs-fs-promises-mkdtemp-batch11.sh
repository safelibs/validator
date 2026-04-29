#!/usr/bin/env bash
# @testcase: usage-nodejs-fs-promises-mkdtemp-batch11
# @title: Node.js fs promises mkdtemp
# @description: Creates a temporary directory through Node.js fs.promises backed by libuv.
# @timeout: 180
# @tags: usage, nodejs, libuv
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-nodejs-fs-promises-mkdtemp-batch11"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

TMP_PARENT="$tmpdir" node >"$tmpdir/out" <<'JS'
const fs = require('fs/promises');
(async () => {
  const dir = await fs.mkdtemp(process.env.TMP_PARENT + '/node-');
  console.log(dir.includes('/node-'));
})().catch(err => { console.error(err); process.exit(1); });
JS
validator_assert_contains "$tmpdir/out" 'true'
