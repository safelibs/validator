#!/usr/bin/env bash
# @testcase: usage-nodejs-fs-write-stream-end
# @title: nodejs fs write stream end
# @description: Writes through a Node fs.createWriteStream and verifies the end callback fires after the buffered payload is flushed.
# @timeout: 180
# @tags: usage, nodejs, stream
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-nodejs-fs-write-stream-end"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

FILE_PATH="$tmpdir/out.bin" node >"$tmpdir/log" <<'JS'
const fs = require('fs');
const path = process.env.FILE_PATH;
const ws = fs.createWriteStream(path);
ws.write('write-stream-payload');
ws.end(() => console.log('done'));
JS
validator_assert_contains "$tmpdir/log" 'done'
validator_assert_contains "$tmpdir/out.bin" 'write-stream-payload'
