#!/usr/bin/env bash
# @testcase: usage-gawk-environ-access
# @title: gawk ENVIRON array access
# @description: Reads an exported environment variable from gawk via the ENVIRON array and verifies the value is recovered exactly.
# @timeout: 180
# @tags: usage, gawk, environment
# @client: gawk

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gawk-environ-access"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export VALIDATOR_GAWK_PROBE='hello-from-environ-2026'

gawk 'BEGIN { print ENVIRON["VALIDATOR_GAWK_PROBE"] }' </dev/null >"$tmpdir/out"

actual=$(cat "$tmpdir/out")
expected='hello-from-environ-2026'
if [[ "$actual" != "$expected" ]]; then
  printf 'ENVIRON readback mismatch:\n actual:   %s\n expected: %s\n' "$actual" "$expected" >&2
  exit 1
fi

unset VALIDATOR_GAWK_PROBE
gawk 'BEGIN { v = ENVIRON["VALIDATOR_GAWK_PROBE"]; print "len=" length(v) }' </dev/null >"$tmpdir/empty.out"
validator_assert_contains "$tmpdir/empty.out" 'len=0'
