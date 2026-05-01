#!/usr/bin/env bash
# @testcase: usage-ttyd-readonly-help-flag
# @title: ttyd writable help flag (readonly default)
# @description: Invokes ttyd --help and verifies that the documented writable option (-W / --writable) is present and is described as the inverse of ttyd's default read-only behavior, since ttyd is read-only by default and exposes no separate --readonly flag.
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
validator_assert_contains "$tmpdir/help.txt" '--writable'
validator_assert_contains "$tmpdir/help.txt" '-W'
grep -Eqi 'readonly by default|read-only by default|readonly' "$tmpdir/help.txt" || {
  printf 'expected ttyd --help to mention readonly default behavior\n' >&2
  sed -n '1,160p' "$tmpdir/help.txt" >&2
  exit 1
}
