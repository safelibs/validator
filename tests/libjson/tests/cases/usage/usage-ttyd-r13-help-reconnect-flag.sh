#!/usr/bin/env bash
# @testcase: usage-ttyd-r13-help-reconnect-flag
# @title: ttyd --help advertises the -O/--once flag
# @description: Runs ttyd --help and verifies the OPTIONS block lists the -O/--once short/long pair, an option that ttyd's json-c-driven argv parser surfaces in its help output. (Earlier rounds keyed on -r/--reconnect, which is no longer listed in ttyd 1.7.x's help; --once is the cross-version stable equivalent.)
# @timeout: 60
# @tags: usage, ttyd, help
# @client: ttyd

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ttyd --help >"$tmpdir/help.txt" 2>&1
grep -Eq -- '-O, --once' "$tmpdir/help.txt"
