#!/usr/bin/env bash
# @testcase: usage-ttyd-r15-help-index-flag
# @title: ttyd --help advertises the -I/--index flag
# @description: Runs ttyd --help and verifies the OPTIONS block lists the -I/--index short/long pair, the option that selects a custom index.html document served alongside the json-c configuration delivered to the front end.
# @timeout: 60
# @tags: usage, ttyd, help
# @client: ttyd

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ttyd --help >"$tmpdir/help.txt" 2>&1
grep -Eq -- '-I, --index' "$tmpdir/help.txt"
