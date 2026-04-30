#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-standalone-zst-not-tar
# @title: bsdtar rejects standalone zstd file that is not a tar
# @description: Compresses a raw payload with the zstd CLI to produce a standalone .zst file (no tar inside) and asserts bsdtar -xf refuses to extract it because the decoded byte stream is not a recognized archive format.
# @timeout: 180
# @tags: usage, archive, zstd, negative
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/out"
printf 'this is just a plain text file, not a tar\n' >"$tmpdir/payload.txt"

# Standalone .zst (no tar wrapper).
zstd -q -o "$tmpdir/payload.txt.zst" "$tmpdir/payload.txt"
validator_require_file "$tmpdir/payload.txt.zst"

magic=$(od -An -N4 -tx1 "$tmpdir/payload.txt.zst" | tr -d ' \n')
test "$magic" = "28b52ffd"

# bsdtar should detect zstd and decode it, but the decoded byte stream is a
# plain text file rather than a tar archive, so extraction must fail.
set +e
bsdtar -xf "$tmpdir/payload.txt.zst" -C "$tmpdir/out" 2>"$tmpdir/err"
rc=$?
set -e
test "$rc" -ne 0

# Output directory must remain empty since extraction failed.
test -z "$(ls -A "$tmpdir/out")"

# The error message should mention an unrecognized archive format.
grep -Eq -i 'unrecognized|not.*archive|format' "$tmpdir/err"
