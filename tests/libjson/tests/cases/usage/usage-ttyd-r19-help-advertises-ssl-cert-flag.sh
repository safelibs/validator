#!/usr/bin/env bash
# @testcase: usage-ttyd-r19-help-advertises-ssl-cert-flag
# @title: ttyd --help advertises the -C/--ssl-cert option
# @description: Captures ttyd --help and asserts the --ssl-cert option appears, pinning the SSL certificate file path flag exposure in the Ubuntu 24.04 ttyd 1.7 CLI surface where option text is materialised via json-c.
# @timeout: 60
# @tags: usage, ttyd, help, ssl-cert, r19
# @client: ttyd

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ttyd --help >"$tmpdir/help.txt" 2>&1 || true
validator_require_file "$tmpdir/help.txt"
grep -Eq -- '--ssl-cert' "$tmpdir/help.txt"
