#!/usr/bin/env bash
# @testcase: usage-ttyd-r12-help-port-flag
# @title: ttyd --help advertises the -p/--port flag
# @description: Runs ttyd --help and verifies the OPTIONS block lists the -p/--port short/long pair used to bind the embedded HTTP server (which itself parses /token requests through json-c).
# @timeout: 60
# @tags: usage, ttyd, help
# @client: ttyd

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ttyd --help >"$tmpdir/help.txt" 2>&1
grep -Eq -- '-p, --port' "$tmpdir/help.txt"
