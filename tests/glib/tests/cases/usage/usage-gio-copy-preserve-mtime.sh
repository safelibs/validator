#!/usr/bin/env bash
# @testcase: usage-gio-copy-preserve-mtime
# @title: gio copy -p preserves modification time
# @description: Copies a file with gio copy -p and verifies the destination's modification timestamp matches the source rather than the current time.
# @timeout: 180
# @tags: usage, gio, filesystem
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gio-copy-preserve-mtime"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'preserve me\n' >"$tmpdir/src.txt"
touch -d '2020-01-15 03:30:00 UTC' "$tmpdir/src.txt"

src_mtime=$(stat -c '%Y' "$tmpdir/src.txt")
gio copy -p "$tmpdir/src.txt" "$tmpdir/dst.txt"
dst_mtime=$(stat -c '%Y' "$tmpdir/dst.txt")

[[ "$src_mtime" == "$dst_mtime" ]] || {
  printf 'mtime not preserved: src=%s dst=%s\n' "$src_mtime" "$dst_mtime" >&2
  exit 1
}

validator_assert_contains "$tmpdir/dst.txt" 'preserve me'
