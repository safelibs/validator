#!/usr/bin/env bash
# @testcase: usage-ttyd-r17-help-advertises-writable-flag
# @title: ttyd --help advertises the -W/--writable flag
# @description: Captures ttyd --help and asserts the -W/--writable flag appears in the OPTIONS block, locking in the writable-mode option as documented in Ubuntu 24.04 ttyd's CLI surface.
# @timeout: 60
# @tags: usage, ttyd, help, writable
# @client: ttyd

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ttyd --help >"$tmpdir/help.txt" 2>&1 || true
validator_require_file "$tmpdir/help.txt"
grep -Eq -- '-W,? --writable' "$tmpdir/help.txt" \
  || grep -Eq -- '--writable' "$tmpdir/help.txt"
