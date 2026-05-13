#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-r16-xzcat-concatenated-streams
# @title: xzcat concatenates output across two physically-concatenated xz streams
# @description: Compresses two payloads with xz -c into two .xz files, concatenates them via shell cat into a multi-stream .xz, and asserts xzcat on that concatenated archive emits BOTH payloads in order — exercising liblzma's stream-iteration decode path.
# @timeout: 60
# @tags: usage, xzcat, multistream, concat
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'stream-one-payload\n' >"$tmpdir/a.txt"
printf 'stream-two-payload\n' >"$tmpdir/b.txt"

xz -c "$tmpdir/a.txt" >"$tmpdir/a.xz"
xz -c "$tmpdir/b.txt" >"$tmpdir/b.xz"
cat "$tmpdir/a.xz" "$tmpdir/b.xz" >"$tmpdir/concat.xz"

xzcat "$tmpdir/concat.xz" >"$tmpdir/out.txt"

validator_assert_contains "$tmpdir/out.txt" 'stream-one-payload'
validator_assert_contains "$tmpdir/out.txt" 'stream-two-payload'

# Order must be preserved.
grep -n . "$tmpdir/out.txt" >"$tmpdir/numbered.txt"
first_line=$(head -n 1 "$tmpdir/numbered.txt")
case "$first_line" in
  *stream-one-payload*) ;;
  *) printf 'expected stream-one-payload first\n' >&2; exit 1;;
esac
