#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-r9-bsdtar-cwd-keep-newer
# @title: bsdtar zstd extract --keep-newer-files
# @description: Extracts a zstd archive over a directory containing a newer copy of a member and asserts --keep-newer-files leaves the existing newer file untouched while extracting the missing one.
# @timeout: 180
# @tags: usage, archive, zstd
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in" "$tmpdir/out"
printf 'archived alpha\n' >"$tmpdir/in/alpha.txt"
printf 'archived beta\n'  >"$tmpdir/in/beta.txt"
# Backdate the archive's source files so the on-disk newer copy wins.
touch -d '2010-01-01' "$tmpdir/in/alpha.txt" "$tmpdir/in/beta.txt"

bsdtar --zstd -cf "$tmpdir/a.tar.zst" -C "$tmpdir/in" .

# Pre-populate alpha.txt with a *newer* version on disk.
printf 'newer alpha on disk\n' >"$tmpdir/out/alpha.txt"
touch -d '2030-01-01' "$tmpdir/out/alpha.txt"

bsdtar -xf "$tmpdir/a.tar.zst" -C "$tmpdir/out" --keep-newer-files 2>"$tmpdir/err" || true

# alpha.txt newer copy retained.
grep -q 'newer alpha on disk' "$tmpdir/out/alpha.txt"
# beta.txt freshly extracted.
[[ -f "$tmpdir/out/beta.txt" ]]
grep -q 'archived beta' "$tmpdir/out/beta.txt"
