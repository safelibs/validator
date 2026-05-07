#!/usr/bin/env bash
# @testcase: usage-ttyd-r15-help-url-arg-flag
# @title: ttyd --help advertises the -a/--url-arg flag
# @description: Runs ttyd --help and verifies the OPTIONS block lists the -a/--url-arg short/long pair, the option that lets clients pass arguments through query strings into the spawned process backing the json-c served front end.
# @timeout: 60
# @tags: usage, ttyd, help
# @client: ttyd

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ttyd --help >"$tmpdir/help.txt" 2>&1
grep -Eq -- '-a, --url-arg' "$tmpdir/help.txt"
