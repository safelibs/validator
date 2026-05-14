#!/usr/bin/env bash
# @testcase: usage-ttyd-r17-help-advertises-base-path-flag
# @title: ttyd --help advertises the -b/--base-path flag
# @description: Captures ttyd --help and asserts the --base-path option appears, pinning the reverse-proxy mount-point flag on Ubuntu 24.04 ttyd 1.7.
# @timeout: 60
# @tags: usage, ttyd, help, base-path
# @client: ttyd

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ttyd --help >"$tmpdir/help.txt" 2>&1 || true
validator_require_file "$tmpdir/help.txt"
grep -Eq -- '--base-path' "$tmpdir/help.txt"
