#!/usr/bin/env bash
# @testcase: usage-ttyd-readonly-help-flag
# @title: ttyd readonly help flag
# @description: Invokes ttyd --help and verifies the documented options include the read-only flag (-R / --readonly) and the writable flag (-W / --writable).
# @timeout: 60
# @tags: usage, ttyd
# @client: ttyd

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-ttyd-readonly-help-flag"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ttyd --help >"$tmpdir/help.txt" 2>&1 || true
validator_require_file "$tmpdir/help.txt"
validator_assert_contains "$tmpdir/help.txt" '--readonly'
grep -Eq -- '(-W|--writable)' "$tmpdir/help.txt" || {
  printf 'expected ttyd --help to document the writable option\n' >&2
  sed -n '1,120p' "$tmpdir/help.txt" >&2
  exit 1
}
