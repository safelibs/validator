#!/usr/bin/env bash
# @testcase: usage-ttyd-r15-help-cwd-flag
# @title: ttyd --help advertises the -w/--cwd flag
# @description: Runs ttyd --help and verifies the OPTIONS block lists the -w/--cwd short/long pair, the option that selects the working directory for the child program whose output is framed into the json-c serialised WebSocket transport.
# @timeout: 60
# @tags: usage, ttyd, help
# @client: ttyd

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ttyd --help >"$tmpdir/help.txt" 2>&1
grep -Eq -- '-w, --cwd' "$tmpdir/help.txt"
