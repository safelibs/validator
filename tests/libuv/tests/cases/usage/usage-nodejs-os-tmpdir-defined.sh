#!/usr/bin/env bash
# @testcase: usage-nodejs-os-tmpdir-defined
# @title: nodejs os.tmpdir defined
# @description: Reads the platform temporary directory through Node os.tmpdir and verifies a non-empty string is returned.
# @timeout: 180
# @tags: usage, nodejs, os
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-nodejs-os-tmpdir-defined"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

node >"$tmpdir/out" <<'JS'
const os = require('os');
const t = os.tmpdir();
if (typeof t !== 'string' || t.length === 0) throw new Error('no tmpdir');
console.log('tmpdir-ok');
JS
validator_assert_contains "$tmpdir/out" 'tmpdir-ok'
