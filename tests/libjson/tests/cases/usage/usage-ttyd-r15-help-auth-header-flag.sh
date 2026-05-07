#!/usr/bin/env bash
# @testcase: usage-ttyd-r15-help-auth-header-flag
# @title: ttyd --help advertises the -H/--auth-header flag
# @description: Runs ttyd --help and verifies the OPTIONS block lists the -H/--auth-header short/long pair, the option that names the HTTP header carrying authentication identity from a reverse proxy fronting the json-c served terminal.
# @timeout: 60
# @tags: usage, ttyd, help
# @client: ttyd

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ttyd --help >"$tmpdir/help.txt" 2>&1
grep -Eq -- '-H, --auth-header' "$tmpdir/help.txt"
