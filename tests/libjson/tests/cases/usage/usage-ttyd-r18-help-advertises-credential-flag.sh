#!/usr/bin/env bash
# @testcase: usage-ttyd-r18-help-advertises-credential-flag
# @title: ttyd --help advertises the -c/--credential basic auth flag
# @description: Captures ttyd --help and asserts the -c/--credential option appears, pinning the basic-authentication flag exposure in the Ubuntu 24.04 ttyd 1.7 CLI surface that parses option text via json-c.
# @timeout: 60
# @tags: usage, ttyd, help, credential, r18
# @client: ttyd

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ttyd --help >"$tmpdir/help.txt" 2>&1 || true
validator_require_file "$tmpdir/help.txt"
grep -Eq -- '--credential' "$tmpdir/help.txt"
