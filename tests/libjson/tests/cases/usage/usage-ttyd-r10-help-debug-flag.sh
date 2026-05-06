#!/usr/bin/env bash
# @testcase: usage-ttyd-r10-help-debug-flag
# @title: ttyd debug help flag documented
# @description: Invokes ttyd --help and verifies the debug verbosity option (-d / --debug) is documented in the option list shipped with Ubuntu 24.04 ttyd 1.7.x.
# @timeout: 60
# @tags: usage, ttyd
# @client: ttyd

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ttyd --help >"$tmpdir/help.txt" 2>&1 || true
validator_require_file "$tmpdir/help.txt"
validator_assert_contains "$tmpdir/help.txt" '--debug'
validator_assert_contains "$tmpdir/help.txt" '-d'
