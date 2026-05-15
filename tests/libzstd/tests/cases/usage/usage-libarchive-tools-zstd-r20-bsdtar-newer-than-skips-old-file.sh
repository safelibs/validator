#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-r20-bsdtar-newer-than-skips-old-file
# @title: bsdtar --zstd --newer-mtime omits members whose mtime predates the cutoff
# @description: Creates two files where one is touched to be older than the other, builds a tar.zst archive with --newer-mtime set to the older file's mtime+10s, lists the archive and asserts the old file is not present while the newer file is — pinning bsdtar's mtime-filter path under zstd compression.
# @timeout: 60
# @tags: usage, archive, bsdtar, zstd, newer-mtime, r20
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/src"
mkdir -p "$src"
echo "old" >"$src/old.txt"
echo "new" >"$src/new.txt"
# old.txt mtime 2020, new.txt mtime 2024
touch -d '2020-01-01 00:00:00 UTC' "$src/old.txt"
touch -d '2024-01-01 00:00:00 UTC' "$src/new.txt"

(cd "$src" && bsdtar --zstd --newer-mtime '2022-01-01 00:00:00 UTC' -cf "$tmpdir/out.tar.zst" old.txt new.txt)

bsdtar --zstd -tf "$tmpdir/out.tar.zst" >"$tmpdir/list.txt"
grep -Fq 'new.txt' "$tmpdir/list.txt" || { echo "expected new.txt in archive" >&2; cat "$tmpdir/list.txt" >&2; exit 1; }
if grep -Fq 'old.txt' "$tmpdir/list.txt"; then
    echo "expected old.txt to be filtered out" >&2
    cat "$tmpdir/list.txt" >&2
    exit 1
fi
