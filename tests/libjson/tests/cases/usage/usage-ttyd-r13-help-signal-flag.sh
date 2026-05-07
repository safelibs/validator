#!/usr/bin/env bash
# @testcase: usage-ttyd-r13-help-signal-flag
# @title: ttyd --help advertises the -s/--signal flag
# @description: Runs ttyd --help and verifies the OPTIONS block lists the -s/--signal short/long pair, the option that selects the signal sent to the spawned process when a client disconnects from the json-c configured server.
# @timeout: 60
# @tags: usage, ttyd, help
# @client: ttyd

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ttyd --help >"$tmpdir/help.txt" 2>&1
grep -Eq -- '-s, --signal' "$tmpdir/help.txt"
