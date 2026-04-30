#!/usr/bin/env bash
# @testcase: usage-ttyd-help-options
# @title: ttyd help options
# @description: Invokes ttyd --help and verifies the documented option flags include the listen interface and base path switches.
# @timeout: 60
# @tags: usage, ttyd
# @client: ttyd

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-ttyd-help-options"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ttyd --help >"$tmpdir/help.txt" 2>&1 || true
validator_require_file "$tmpdir/help.txt"
validator_assert_contains "$tmpdir/help.txt" '--port'
validator_assert_contains "$tmpdir/help.txt" '--interface'
validator_assert_contains "$tmpdir/help.txt" '--base-path'
