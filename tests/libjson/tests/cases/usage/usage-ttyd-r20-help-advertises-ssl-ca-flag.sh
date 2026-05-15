#!/usr/bin/env bash
# @testcase: usage-ttyd-r20-help-advertises-ssl-ca-flag
# @title: ttyd --help advertises the -A/--ssl-ca flag
# @description: Captures ttyd --help and asserts the --ssl-ca option appears, pinning the client-certificate CA file flag exposure in the Ubuntu 24.04 ttyd 1.7 CLI surface where option text is materialised via json-c.
# @timeout: 60
# @tags: usage, ttyd, help, ssl-ca, r20
# @client: ttyd

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ttyd --help >"$tmpdir/help.txt" 2>&1 || true
validator_require_file "$tmpdir/help.txt"
grep -Eq -- '--ssl-ca' "$tmpdir/help.txt"
