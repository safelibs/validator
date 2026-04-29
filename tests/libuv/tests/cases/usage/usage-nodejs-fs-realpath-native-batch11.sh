#!/usr/bin/env bash
# @testcase: usage-nodejs-fs-realpath-native-batch11
# @title: Node.js realpath native
# @description: Resolves a native realpath through Node.js filesystem bindings.
# @timeout: 180
# @tags: usage, nodejs, libuv
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-nodejs-fs-realpath-native-batch11"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

FILE_PATH="$tmpdir/real.txt" node >"$tmpdir/out" <<'JS'
const fs = require('fs');
fs.writeFileSync(process.env.FILE_PATH, 'realpath');
console.log(fs.realpathSync.native(process.env.FILE_PATH).endsWith('real.txt'));
JS
validator_assert_contains "$tmpdir/out" 'true'
