#!/usr/bin/env bash
# @testcase: usage-ttyd-r12-help-interface-flag
# @title: ttyd --help advertises the -i/--interface flag
# @description: Runs ttyd --help and verifies the OPTIONS block lists the -i/--interface short/long pair used to constrain the listener address served by the json-c configured HTTP front-end.
# @timeout: 60
# @tags: usage, ttyd, help
# @client: ttyd

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ttyd --help >"$tmpdir/help.txt" 2>&1
grep -Eq -- '-i, --interface' "$tmpdir/help.txt"
