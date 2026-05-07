#!/usr/bin/env bash
# @testcase: usage-ttyd-r13-help-reconnect-flag
# @title: ttyd --help advertises the -r/--reconnect flag
# @description: Runs ttyd --help and verifies the OPTIONS block lists the -r/--reconnect short/long pair, the option that controls the auto-reconnect interval emitted into the json-c configured client bootstrap.
# @timeout: 60
# @tags: usage, ttyd, help
# @client: ttyd

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ttyd --help >"$tmpdir/help.txt" 2>&1
grep -Eq -- '-r, --reconnect' "$tmpdir/help.txt"
