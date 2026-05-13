#!/usr/bin/env bash
# @testcase: usage-ttyd-r16-help-uid-gid-flags
# @title: ttyd --help advertises both -u/--uid and -g/--gid flags
# @description: Invokes ttyd --help and asserts the documented uid and gid drop-privileges flags are present, distinct from credential and auth-header coverage in earlier rounds.
# @timeout: 60
# @tags: usage, ttyd, help, privileges
# @client: ttyd

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ttyd --help >"$tmpdir/help.txt" 2>&1 || true
validator_require_file "$tmpdir/help.txt"
grep -Eq -- '-u, --uid' "$tmpdir/help.txt"
grep -Eq -- '-g, --gid' "$tmpdir/help.txt"
