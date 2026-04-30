#!/usr/bin/env bash
# @testcase: usage-tar-xform-rename
# @title: tar transform member rename
# @description: Creates a tar archive with --transform sed-style renaming and verifies that the listed and extracted member uses the rewritten name.
# @timeout: 180
# @tags: usage, tar, archive
# @client: tar

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-tar-xform-rename"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in" "$tmpdir/out"
printf 'xform payload\n' >"$tmpdir/in/source.txt"

tar -cf "$tmpdir/archive.tar" -C "$tmpdir/in" \
  --transform='s,source\.txt,renamed.txt,' source.txt

tar -tf "$tmpdir/archive.tar" >"$tmpdir/list"
validator_assert_contains "$tmpdir/list" 'renamed.txt'
if grep -q '^source.txt$' "$tmpdir/list"; then
  printf 'source.txt should have been renamed by --transform\n' >&2
  exit 1
fi

tar -xf "$tmpdir/archive.tar" -C "$tmpdir/out"
validator_assert_contains "$tmpdir/out/renamed.txt" 'xform payload'
