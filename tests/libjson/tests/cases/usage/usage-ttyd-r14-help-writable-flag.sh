#!/usr/bin/env bash
# @testcase: usage-ttyd-r14-help-writable-flag
# @title: ttyd --help advertises the -W/--writable flag
# @description: Runs ttyd --help and verifies the OPTIONS block lists the -W/--writable short/long pair, the option that toggles whether clients of the json-c served front end may write to the spawned process.
# @timeout: 60
# @tags: usage, ttyd, help
# @client: ttyd

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ttyd --help >"$tmpdir/help.txt" 2>&1
grep -Eq -- '-W, --writable' "$tmpdir/help.txt"
