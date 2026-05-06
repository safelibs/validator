#!/usr/bin/env bash
# @testcase: usage-ttyd-r11-help-ssl-flags
# @title: ttyd --help advertises -S/--ssl with -C/-K certificate flag pair
# @description: Runs ttyd --help and verifies the OPTIONS block lists the SSL trio (-S/--ssl, -C/--ssl-cert, -K/--ssl-key) so the json-c configured server can be brought up over TLS.
# @timeout: 60
# @tags: usage, ttyd, help, ssl
# @client: ttyd

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ttyd --help >"$tmpdir/help.txt" 2>&1
grep -Eq -- '-S, --ssl' "$tmpdir/help.txt"
grep -Eq -- '-C, --ssl-cert' "$tmpdir/help.txt"
grep -Eq -- '-K, --ssl-key' "$tmpdir/help.txt"
