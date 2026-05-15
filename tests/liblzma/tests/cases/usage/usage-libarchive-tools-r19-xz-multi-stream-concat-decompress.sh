#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-r19-xz-multi-stream-concat-decompress
# @title: xz -d concatenates two .xz streams into the joined original payload
# @description: Compresses two payloads separately into single-stream .xz files, concatenates the bytes, runs xz -dc on the joined stream, and asserts the output equals "alpha" followed by "beta", pinning the multi-stream decoder concatenation contract.
# @timeout: 60
# @tags: usage, xz, multi-stream, concat, r19
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'alpha' >"$tmpdir/a.bin"
printf 'beta'  >"$tmpdir/b.bin"

xz -c "$tmpdir/a.bin" >"$tmpdir/a.xz"
xz -c "$tmpdir/b.bin" >"$tmpdir/b.xz"
cat "$tmpdir/a.xz" "$tmpdir/b.xz" >"$tmpdir/ab.xz"

xz -dc "$tmpdir/ab.xz" >"$tmpdir/out.bin"
out=$(cat "$tmpdir/out.bin")
[[ "$out" == "alphabeta" ]] || {
  printf 'expected alphabeta, got %s\n' "$out" >&2; exit 1;
}
