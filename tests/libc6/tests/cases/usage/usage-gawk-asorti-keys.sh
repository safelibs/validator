#!/usr/bin/env bash
# @testcase: usage-gawk-asorti-keys
# @title: gawk asorti sorts associative keys
# @description: Builds an associative array in gawk and sorts its keys with asorti under LC_ALL=C, then prints them in order to verify deterministic ordering.
# @timeout: 60
# @tags: usage, gawk, locale
# @client: gawk

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gawk-asorti-keys"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

LC_ALL=C gawk 'BEGIN {
  m["zebra"] = 1
  m["apple"] = 2
  m["mango"] = 3
  n = asorti(m, keys)
  for (i = 1; i <= n; i++) printf "%d:%s\n", i, keys[i]
}' >"$tmpdir/out"

printf '1:apple\n2:mango\n3:zebra\n' >"$tmpdir/expected"
cmp "$tmpdir/expected" "$tmpdir/out"
