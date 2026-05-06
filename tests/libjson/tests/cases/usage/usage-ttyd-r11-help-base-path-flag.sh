#!/usr/bin/env bash
# @testcase: usage-ttyd-r11-help-base-path-flag
# @title: ttyd --help advertises the -b/--base-path reverse-proxy flag
# @description: Runs ttyd --help and verifies the OPTIONS block lists the long-form -b/--base-path flag exactly as documented for reverse-proxy mounting (json-c parses /token responses for that mode).
# @timeout: 60
# @tags: usage, ttyd, help
# @client: ttyd

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ttyd --help >"$tmpdir/help.txt" 2>&1
grep -Eq -- '-b, --base-path' "$tmpdir/help.txt"
