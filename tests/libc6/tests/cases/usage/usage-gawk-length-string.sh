#!/usr/bin/env bash
# @testcase: usage-gawk-length-string
# @title: gawk length() over fields and lines
# @description: Computes per-line field counts and the maximum string length across an input via gawk length() to exercise libc-backed string measurement.
# @timeout: 120
# @tags: usage, gawk, libc
# @client: gawk

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gawk-length-string"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.txt" <<'EOF'
alpha beta gamma
delta epsilon
zeta eta theta iota
EOF

gawk '
{
  if (length($0) > maxlen) maxlen = length($0)
  printf "fields=%d len=%d\n", NF, length($0)
}
END { printf "maxlen=%d\n", maxlen }
' "$tmpdir/in.txt" >"$tmpdir/out"

validator_assert_contains "$tmpdir/out" 'fields=3 len=16'
validator_assert_contains "$tmpdir/out" 'fields=2 len=13'
validator_assert_contains "$tmpdir/out" 'fields=4 len=19'
validator_assert_contains "$tmpdir/out" 'maxlen=19'
