#!/usr/bin/env bash
# @testcase: usage-ttyd-r19-help-advertises-ssl-key-flag
# @title: ttyd --help advertises the -K/--ssl-key option
# @description: Captures ttyd --help and asserts the --ssl-key option appears, pinning the SSL key file path flag exposure in the Ubuntu 24.04 ttyd 1.7 CLI surface where option text is materialised via json-c.
# @timeout: 60
# @tags: usage, ttyd, help, ssl-key, r19
# @client: ttyd

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ttyd --help >"$tmpdir/help.txt" 2>&1 || true
validator_require_file "$tmpdir/help.txt"
grep -Eq -- '--ssl-key' "$tmpdir/help.txt"
