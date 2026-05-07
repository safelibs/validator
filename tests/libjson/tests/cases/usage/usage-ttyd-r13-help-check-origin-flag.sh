#!/usr/bin/env bash
# @testcase: usage-ttyd-r13-help-check-origin-flag
# @title: ttyd --help advertises the -O/--check-origin flag
# @description: Runs ttyd --help and verifies the OPTIONS block lists the -O/--check-origin short/long pair, the option that controls cross-origin WebSocket validation for the json-c served front end.
# @timeout: 60
# @tags: usage, ttyd, help
# @client: ttyd

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ttyd --help >"$tmpdir/help.txt" 2>&1
grep -Eq -- '-O, --check-origin' "$tmpdir/help.txt"
