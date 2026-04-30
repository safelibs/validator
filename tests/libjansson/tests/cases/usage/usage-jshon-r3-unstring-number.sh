#!/usr/bin/env bash
# @testcase: usage-jshon-r3-unstring-number
# @title: jshon -u prints numeric values without quotes
# @description: Applies jshon -u to integer, negative, fractional, and scientific JSON number values and verifies the bare digit form is emitted on stdout exactly as in the source document.
# @timeout: 120
# @tags: usage, json, jshon
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-r3-unstring-number"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

probe_unstring_number() {
  local document=$1
  local key=$2
  local expected_substr=$3
  local label=$4

  printf '%s' "$document" | jshon -e "$key" -u >"$tmpdir/out-$label"
  if ! grep -Fq -- "$expected_substr" "$tmpdir/out-$label"; then
    printf 'expected %s in -u output for %s, got:\n' \
      "$expected_substr" "$label" >&2
    cat "$tmpdir/out-$label" >&2
    exit 1
  fi
  # The output must NOT be a quoted JSON string.
  if grep -Fq -- '"' "$tmpdir/out-$label"; then
    printf 'unexpected quote character in -u number output for %s:\n' "$label" >&2
    cat "$tmpdir/out-$label" >&2
    exit 1
  fi
}

probe_unstring_number '{"v":7}'        v 7       int
probe_unstring_number '{"v":-15}'      v -15     neg
probe_unstring_number '{"v":3.5}'      v 3.5     frac
# jshon parses scientific notation through jansson and re-emits the
# expanded decimal form (1.5e2 -> 150.0). Anchor on the expanded value.
probe_unstring_number '{"v":1.5e2}'    v 150     sci

# Numeric value inside an array, fetched then unstringed, must be bare digits.
printf '%s' '[99]' | jshon -e 0 -u >"$tmpdir/out-arr"
grep -Fxq -- '99' "$tmpdir/out-arr" || {
  printf 'expected bare 99 from array element, got:\n' >&2
  cat "$tmpdir/out-arr" >&2
  exit 1
}
