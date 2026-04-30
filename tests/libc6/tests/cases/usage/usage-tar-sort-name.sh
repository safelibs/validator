#!/usr/bin/env bash
# @testcase: usage-tar-sort-name
# @title: tar --sort=name deterministic member ordering
# @description: Creates two tar archives with --sort=name from differently-ordered inputs and verifies the listings are byte-identical and lexicographically sorted.
# @timeout: 180
# @tags: usage, tar, archive
# @client: tar

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-tar-sort-name"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Two source trees with files materialized in different filesystem orderings
# so that an unsorted directory walk would produce different listings.
mkdir -p "$tmpdir/src1" "$tmpdir/src2"
for f in gamma alpha delta beta; do
  printf '%s\n' "$f" >"$tmpdir/src1/$f.txt"
done
for f in beta delta alpha gamma; do
  printf '%s\n' "$f" >"$tmpdir/src2/$f.txt"
done

# tar --sort=name forces the directory walk into lexicographic order.
tar --sort=name -cf "$tmpdir/one.tar" -C "$tmpdir/src1" .
tar --sort=name -cf "$tmpdir/two.tar" -C "$tmpdir/src2" .

tar -tf "$tmpdir/one.tar" | grep -E '\.txt$' >"$tmpdir/list-one"
tar -tf "$tmpdir/two.tar" | grep -E '\.txt$' >"$tmpdir/list-two"

# Listings must match byte-for-byte.
cmp "$tmpdir/list-one" "$tmpdir/list-two"

test "$(wc -l <"$tmpdir/list-one")" -eq 4

# Listing must be lexicographically sorted.
test "$(sed -n '1p' "$tmpdir/list-one")" = './alpha.txt'
test "$(sed -n '2p' "$tmpdir/list-one")" = './beta.txt'
test "$(sed -n '3p' "$tmpdir/list-one")" = './delta.txt'
test "$(sed -n '4p' "$tmpdir/list-one")" = './gamma.txt'
