#!/usr/bin/env bash
# @testcase: usage-gio-set-attribute
# @title: gio set adjusts unix mode attribute
# @description: Sets the unix::mode attribute via gio set and verifies the new permissions on disk.
# @timeout: 120
# @tags: usage, gio, filesystem
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gio-set-attribute"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'attribute payload\n' >"$tmpdir/file.txt"
chmod 0644 "$tmpdir/file.txt"

# unix::mode takes a uint32 value; 0644 octal = 420 decimal
gio set -t uint32 "$tmpdir/file.txt" unix::mode 420
mode_before=$(stat -c '%a' "$tmpdir/file.txt")
[[ "$mode_before" = "644" ]] || {
  printf 'expected mode 644 before flip, got %s\n' "$mode_before" >&2
  exit 1
}

# 0600 octal = 384 decimal
gio set -t uint32 "$tmpdir/file.txt" unix::mode 384
mode_after=$(stat -c '%a' "$tmpdir/file.txt")
[[ "$mode_after" = "600" ]] || {
  printf 'expected mode 600 after gio set, got %s\n' "$mode_after" >&2
  exit 1
}
