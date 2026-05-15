#!/usr/bin/env bash
# @testcase: usage-ttyd-r20-help-advertises-socket-owner-flag
# @title: ttyd --help advertises the -U/--socket-owner flag
# @description: Captures ttyd --help and asserts the --socket-owner option appears, pinning the UNIX domain socket file owner flag exposure in the Ubuntu 24.04 ttyd 1.7 CLI surface where option text is materialised via json-c.
# @timeout: 60
# @tags: usage, ttyd, help, socket-owner, r20
# @client: ttyd

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ttyd --help >"$tmpdir/help.txt" 2>&1 || true
validator_require_file "$tmpdir/help.txt"
grep -Eq -- '--socket-owner' "$tmpdir/help.txt"
