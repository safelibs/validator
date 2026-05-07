#!/usr/bin/env bash
# @testcase: usage-ttyd-r14-help-ping-interval-flag
# @title: ttyd --help advertises the -P/--ping-interval flag
# @description: Runs ttyd --help and verifies the OPTIONS block lists the -P/--ping-interval short/long pair, the option that controls keep-alive pings on the WebSocket transport carrying the json-c framed messages.
# @timeout: 60
# @tags: usage, ttyd, help
# @client: ttyd

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ttyd --help >"$tmpdir/help.txt" 2>&1
grep -Eq -- '-P, --ping-interval' "$tmpdir/help.txt"
