#!/usr/bin/env bash
# @testcase: usage-gio-copy-empty-file
# @title: gio copy preserves empty file
# @description: Copies a zero-byte source file with gio copy and verifies the destination exists and remains zero bytes.
# @timeout: 120
# @tags: usage, gio, filesystem
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gio-copy-empty-file"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

: >"$tmpdir/empty.src"
gio copy "$tmpdir/empty.src" "$tmpdir/empty.dst"

[[ -f "$tmpdir/empty.dst" ]] || {
  printf 'expected destination empty.dst to exist\n' >&2
  exit 1
}

size=$(stat -c '%s' "$tmpdir/empty.dst")
[[ "$size" = "0" ]] || {
  printf 'expected size 0 got %s\n' "$size" >&2
  exit 1
}
