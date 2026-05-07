#!/usr/bin/env bash
# @testcase: usage-gio-r15-copy-then-remove-cycle
# @title: gio copy then gio remove leaves only the destination file
# @description: Writes a payload to source.txt, runs gio copy to dest.txt, then gio remove against source.txt, and asserts the destination retains the bytes while the source no longer exists.
# @timeout: 60
# @tags: usage, gio, copy, remove
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'r15-copy-remove\n' >"$tmpdir/source.txt"
gio copy "$tmpdir/source.txt" "$tmpdir/dest.txt"
gio remove "$tmpdir/source.txt"

validator_require_file "$tmpdir/dest.txt"
if [[ -e "$tmpdir/source.txt" ]]; then
  printf 'gio remove did not delete source\n' >&2
  exit 1
fi
validator_assert_contains "$tmpdir/dest.txt" 'r15-copy-remove'
