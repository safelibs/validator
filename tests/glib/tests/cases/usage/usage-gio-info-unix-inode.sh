#!/usr/bin/env bash
# @testcase: usage-gio-info-unix-inode
# @title: gio info reports unix::inode attribute
# @description: Queries the unix::inode file attribute through gio info -a and verifies the reported inode matches the value reported by stat(1).
# @timeout: 120
# @tags: usage, gio, attributes
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gio-info-unix-inode"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'inode payload\n' >"$tmpdir/file.txt"
gio info -a unix::inode "$tmpdir/file.txt" >"$tmpdir/out"

validator_assert_contains "$tmpdir/out" 'unix::inode:'

stat_inode=$(stat -c '%i' "$tmpdir/file.txt")
gio_inode=$(grep -E '^[[:space:]]*unix::inode:' "$tmpdir/out" | head -1 | awk '{print $NF}')
if [[ -z "$gio_inode" ]]; then
  printf 'gio info did not emit a unix::inode value\n' >&2
  sed -n '1,40p' "$tmpdir/out" >&2
  exit 1
fi
if [[ "$gio_inode" != "$stat_inode" ]]; then
  printf 'inode mismatch: gio=%s stat=%s\n' "$gio_inode" "$stat_inode" >&2
  exit 1
fi
