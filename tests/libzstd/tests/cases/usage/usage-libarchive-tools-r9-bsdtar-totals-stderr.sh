#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-r9-bsdtar-totals-stderr
# @title: bsdtar zstd --totals reports byte count
# @description: Creates a zstd-compressed archive with --totals and verifies bsdtar prints a 'Total bytes' summary line to stderr containing a digit count.
# @timeout: 180
# @tags: usage, archive, zstd
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in"
printf 'totals payload one\n' >"$tmpdir/in/a.txt"
printf 'totals payload two\n' >"$tmpdir/in/b.txt"

bsdtar --zstd --totals -cf "$tmpdir/a.tar.zst" -C "$tmpdir/in" . 2>"$tmpdir/err"

# bsdtar emits a "Total bytes written" or similar line on stderr.
grep -Eqi 'total[s]?.*[0-9]+' "$tmpdir/err" || {
  echo "expected totals on stderr:" >&2
  cat "$tmpdir/err" >&2
  exit 1
}

magic=$(od -An -N4 -tx1 "$tmpdir/a.tar.zst" | tr -d ' \n')
test "$magic" = "28b52ffd"
