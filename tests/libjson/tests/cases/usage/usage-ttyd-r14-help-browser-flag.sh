#!/usr/bin/env bash
# @testcase: usage-ttyd-r14-help-browser-flag
# @title: ttyd --help advertises the -B/--browser flag
# @description: Runs ttyd --help and verifies the OPTIONS block lists the -B/--browser short/long pair, the option that opens a system browser tab against the json-c served front end after ttyd starts.
# @timeout: 60
# @tags: usage, ttyd, help
# @client: ttyd

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ttyd --help >"$tmpdir/help.txt" 2>&1
grep -Eq -- '-B, --browser' "$tmpdir/help.txt"
