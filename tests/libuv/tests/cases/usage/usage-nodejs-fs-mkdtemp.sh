#!/usr/bin/env bash
# @testcase: usage-nodejs-fs-mkdtemp
# @title: Node.js fs mkdtemp
# @description: Creates a temporary directory with fs.mkdtempSync and verifies the generated prefix.
# @timeout: 180
# @tags: usage, nodejs, fs
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-nodejs-fs-mkdtemp"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

TMPROOT="$tmpdir" node >"$tmpdir/out" <<'JS'
const fs = require('fs');
const path = require('path');
const target = fs.mkdtempSync(path.join(process.env.TMPROOT, 'uv-'));
console.log(path.basename(target).startsWith('uv-'));
JS
validator_assert_contains "$tmpdir/out" 'true'
