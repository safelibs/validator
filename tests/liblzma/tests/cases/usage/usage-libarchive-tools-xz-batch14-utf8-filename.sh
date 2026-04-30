#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-batch14-utf8-filename
# @title: bsdtar xz utf-8 filename preserved
# @description: Archives a file whose name contains non-ASCII UTF-8 characters into tar.xz and verifies the name and contents are preserved through a liblzma round-trip.
# @timeout: 180
# @tags: usage, archive, xz
# @client: libarchive-tools

set -euo pipefail
export LC_ALL=C.UTF-8
export LANG=C.UTF-8
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in" "$tmpdir/out"

utf_name=$(python3 -c 'import sys; sys.stdout.write("é-café-中文-ñ.txt")')
printf 'utf8 payload\n' >"$tmpdir/in/$utf_name"
src_sha=$(sha256sum "$tmpdir/in/$utf_name" | awk '{print $1}')

bsdtar -cJf "$tmpdir/a.tar.xz" -C "$tmpdir/in" "$utf_name"

magic_hex=$(head -c 6 "$tmpdir/a.tar.xz" | od -An -tx1 | tr -d ' \n')
test "$magic_hex" = "fd377a585a00"

bsdtar -tf "$tmpdir/a.tar.xz" >"$tmpdir/list.txt"
test "$(grep -cFx "$utf_name" "$tmpdir/list.txt")" = "1"

bsdtar -xf "$tmpdir/a.tar.xz" -C "$tmpdir/out"
test -f "$tmpdir/out/$utf_name"

out_sha=$(sha256sum "$tmpdir/out/$utf_name" | awk '{print $1}')
[[ "$src_sha" == "$out_sha" ]] || {
  printf 'sha mismatch: %s vs %s\n' "$src_sha" "$out_sha" >&2
  exit 1
}
