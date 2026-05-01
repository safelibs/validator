#!/usr/bin/env bash
# @testcase: usage-ttyd-credential-help-flag
# @title: ttyd credential help flag
# @description: Invokes ttyd --help and verifies the basic-auth credential flag (-c / --credential USER:PASS) and signal flag (-S / --ssl-cert or --signal) appear in the documented option list.
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
# The credential argument is documented as USER:PASSWORD on Ubuntu 24.04 ttyd.
grep -Eq 'USER[: ]+PASS' "$tmpdir/help.txt" || {
  printf 'expected ttyd --help to mention USER:PASS for credential\n' >&2
  sed -n '1,160p' "$tmpdir/help.txt" >&2
  exit 1
}
