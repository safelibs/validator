#!/usr/bin/env bash
# @testcase: usage-ttyd-credential-help-flag
# @title: ttyd credential help flag
# @description: Invokes ttyd --help and verifies the basic-auth credential flag (-c / --credential) is documented with the username:password format on Ubuntu 24.04 ttyd.
# @timeout: 60
# @tags: usage, ttyd
# @client: ttyd

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-ttyd-credential-help-flag"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ttyd --help >"$tmpdir/help.txt" 2>&1 || true
validator_require_file "$tmpdir/help.txt"
validator_assert_contains "$tmpdir/help.txt" '--credential'
validator_assert_contains "$tmpdir/help.txt" '-c'
# Ubuntu 24.04 ttyd 1.7.x documents the credential format as username:password.
grep -Eqi 'username[ ]*:[ ]*password|username:password' "$tmpdir/help.txt" || {
  printf 'expected ttyd --help to mention username:password for credential\n' >&2
  sed -n '1,160p' "$tmpdir/help.txt" >&2
  exit 1
}
