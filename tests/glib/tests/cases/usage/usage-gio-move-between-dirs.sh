#!/usr/bin/env bash
# @testcase: usage-gio-move-between-dirs
# @title: gio move relocates file between directories
# @description: Moves a file with gio move from one directory to another and verifies the source no longer exists while the destination directory holds the payload.
# @timeout: 180
# @tags: usage, gio, filesystem
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gio-move-between-dirs"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/src" "$tmpdir/dst"
printf 'relocate payload\n' >"$tmpdir/src/file.txt"

gio move "$tmpdir/src/file.txt" "$tmpdir/dst/file.txt"

[[ ! -e "$tmpdir/src/file.txt" ]] || {
  printf 'source still present after move: %s\n' "$tmpdir/src/file.txt" >&2
  exit 1
}

validator_require_file "$tmpdir/dst/file.txt"
validator_assert_contains "$tmpdir/dst/file.txt" 'relocate payload'
