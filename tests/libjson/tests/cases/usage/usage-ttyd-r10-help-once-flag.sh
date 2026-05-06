#!/usr/bin/env bash
# @testcase: usage-ttyd-r10-help-once-flag
# @title: ttyd once-mode help flag documented
# @description: Invokes ttyd --help and verifies the single-session mode option (-o / --once) is documented in the option list shipped with Ubuntu 24.04 ttyd 1.7.x.
# @timeout: 60
# @tags: usage, ttyd
# @client: ttyd

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ttyd --help >"$tmpdir/help.txt" 2>&1 || true
validator_require_file "$tmpdir/help.txt"
validator_assert_contains "$tmpdir/help.txt" '--once'
validator_assert_contains "$tmpdir/help.txt" '-o'
