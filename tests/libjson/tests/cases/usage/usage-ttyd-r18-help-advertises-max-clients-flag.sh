#!/usr/bin/env bash
# @testcase: usage-ttyd-r18-help-advertises-max-clients-flag
# @title: ttyd --help advertises the -m/--max-clients flag
# @description: Captures ttyd --help output and asserts the -m/--max-clients option appears, pinning the client-cap CLI flag exposure on Ubuntu 24.04 ttyd, whose configuration handling relies on json-c.
# @timeout: 60
# @tags: usage, ttyd, help, max-clients, r18
# @client: ttyd

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ttyd --help >"$tmpdir/help.txt" 2>&1 || true
validator_require_file "$tmpdir/help.txt"
grep -Eq -- '--max-clients' "$tmpdir/help.txt"
