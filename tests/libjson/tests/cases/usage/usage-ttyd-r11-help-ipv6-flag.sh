#!/usr/bin/env bash
# @testcase: usage-ttyd-r11-help-ipv6-flag
# @title: ttyd --help advertises the -6/--ipv6 flag
# @description: Runs ttyd --help and verifies the OPTIONS block lists the -6/--ipv6 short/long pair, exposing the IPv6 listener mode that shares the same json-c config plumbing as IPv4.
# @timeout: 60
# @tags: usage, ttyd, help, ipv6
# @client: ttyd

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ttyd --help >"$tmpdir/help.txt" 2>&1
grep -Eq -- '-6, --ipv6' "$tmpdir/help.txt"
