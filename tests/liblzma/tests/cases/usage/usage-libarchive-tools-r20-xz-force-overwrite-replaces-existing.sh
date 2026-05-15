#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-r20-xz-force-overwrite-replaces-existing
# @title: xz --force overwrites an existing .xz output file with a fresh stream
# @description: Pre-populates "in.txt.xz" with sentinel placeholder bytes, then runs xz --keep --force on in.txt and asserts the .xz file no longer contains the sentinel and decompresses back to the original in.txt payload, pinning xz's --force overwrite semantics.
# @timeout: 60
# @tags: usage, xz, force, overwrite, r20
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'r20 force overwrite payload\n' >"$tmpdir/in.txt"
printf 'SENTINEL-PLACEHOLDER-NOT-XZ' >"$tmpdir/in.txt.xz"

xz --keep --force "$tmpdir/in.txt"
validator_require_file "$tmpdir/in.txt.xz"

if grep -aq 'SENTINEL-PLACEHOLDER' "$tmpdir/in.txt.xz"; then
  printf 'sentinel still present in output\n' >&2
  exit 1
fi

xz -dc "$tmpdir/in.txt.xz" >"$tmpdir/decoded.txt"
cmp "$tmpdir/decoded.txt" "$tmpdir/in.txt"
