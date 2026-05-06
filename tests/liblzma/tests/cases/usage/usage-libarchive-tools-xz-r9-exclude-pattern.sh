#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-r9-exclude-pattern
# @title: bsdtar xz --exclude pattern filter
# @description: Builds an xz tarball with bsdtar --exclude '*.tmp' and verifies matching files are absent from the listing.
# @timeout: 180
# @tags: usage, archive, compression
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in"
printf 'keep\n' >"$tmpdir/in/keep.txt"
printf 'drop\n' >"$tmpdir/in/drop.tmp"
printf 'also\n' >"$tmpdir/in/also.tmp"

( cd "$tmpdir/in" && bsdtar --exclude '*.tmp' -cJf "$tmpdir/a.tar.xz" . )

bsdtar -tf "$tmpdir/a.tar.xz" >"$tmpdir/list.txt"
grep -q 'keep.txt' "$tmpdir/list.txt" || { printf 'missing keep.txt\n' >&2; exit 1; }
if grep -qE '\.tmp$' "$tmpdir/list.txt"; then
  printf 'unexpected .tmp file in listing\n' >&2; cat "$tmpdir/list.txt" >&2; exit 1;
fi
