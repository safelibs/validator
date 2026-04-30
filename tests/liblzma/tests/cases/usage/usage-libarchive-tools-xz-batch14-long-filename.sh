#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-batch14-long-filename
# @title: bsdtar xz long filename round-trip
# @description: Archives a file whose name is longer than 200 characters into tar.xz, then extracts and verifies the long name and content survive a liblzma round-trip.
# @timeout: 180
# @tags: usage, archive, xz
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in" "$tmpdir/out"

long_name=$(python3 -c 'import sys; sys.stdout.write("ab" * 120 + ".txt")')
test "${#long_name}" -gt 200

printf 'long name payload\n' >"$tmpdir/in/$long_name"
src_sha=$(sha256sum "$tmpdir/in/$long_name" | awk '{print $1}')

bsdtar -cJf "$tmpdir/a.tar.xz" -C "$tmpdir/in" "$long_name"

magic_hex=$(head -c 6 "$tmpdir/a.tar.xz" | od -An -tx1 | tr -d ' \n')
test "$magic_hex" = "fd377a585a00"

bsdtar -tf "$tmpdir/a.tar.xz" >"$tmpdir/list.txt"
test "$(grep -cFx "$long_name" "$tmpdir/list.txt")" = "1"

bsdtar -xf "$tmpdir/a.tar.xz" -C "$tmpdir/out"
test -f "$tmpdir/out/$long_name"

out_sha=$(sha256sum "$tmpdir/out/$long_name" | awk '{print $1}')
[[ "$src_sha" == "$out_sha" ]] || {
  printf 'sha mismatch: %s vs %s\n' "$src_sha" "$out_sha" >&2
  exit 1
}
