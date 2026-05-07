#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-r12-bsdtar-newer-than-filter
# @title: bsdtar --zstd --newer-mtime skips files older than the cutoff timestamp
# @description: Builds a directory with one old and one fresh file, archives with bsdtar --zstd --newer-mtime set between their mtimes, and asserts the resulting zstd tar lists only the fresh file.
# @timeout: 120
# @tags: usage, archive, zstd, bsdtar, filter
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in"
printf 'old file body\n' >"$tmpdir/in/old.txt"
printf 'new file body\n' >"$tmpdir/in/new.txt"

# Pin both mtimes deterministically.
touch -d '2020-01-01 00:00:00 UTC' "$tmpdir/in/old.txt"
touch -d '2024-06-01 12:00:00 UTC' "$tmpdir/in/new.txt"

bsdtar --zstd --newer-mtime '2022-01-01 00:00:00 UTC' \
    -cf "$tmpdir/out.tar.zst" -C "$tmpdir/in" old.txt new.txt

bsdtar -tf "$tmpdir/out.tar.zst" >"$tmpdir/listing"
grep -q '^new.txt$' "$tmpdir/listing"
if grep -q '^old.txt$' "$tmpdir/listing"; then
    printf 'expected old.txt to be filtered out by --newer-than\n' >&2
    cat "$tmpdir/listing" >&2
    exit 1
fi
