#!/usr/bin/env bash
# @testcase: usage-ttyd-r13-help-terminal-type-flag
# @title: ttyd --help advertises the -T/--terminal-type flag
# @description: Runs ttyd --help and verifies the OPTIONS block lists the -T/--terminal-type short/long pair, the option that selects the TERM string ttyd advertises to its json-c configured front end.
# @timeout: 60
# @tags: usage, ttyd, help
# @client: ttyd

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ttyd --help >"$tmpdir/help.txt" 2>&1
grep -Eq -- '-T, --terminal-type' "$tmpdir/help.txt"
