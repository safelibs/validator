#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-r9-keep-newer-files
# @title: bsdtar xz --keep-newer-files preserves newer
# @description: Extracts an xz tarball over a destination whose existing file is newer and verifies bsdtar --keep-newer-files leaves the existing newer file untouched.
# @timeout: 180
# @tags: usage, archive, compression
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in" "$tmpdir/out"
printf 'archived-content\n' >"$tmpdir/in/data.txt"
touch -d '2010-01-01 00:00:00' "$tmpdir/in/data.txt"
( cd "$tmpdir/in" && bsdtar -cJf "$tmpdir/a.tar.xz" data.txt )

# Create a NEWER existing file at destination.
printf 'existing-newer\n' >"$tmpdir/out/data.txt"
touch -d '2025-06-01 00:00:00' "$tmpdir/out/data.txt"

bsdtar -xf "$tmpdir/a.tar.xz" -C "$tmpdir/out" --keep-newer-files 2>"$tmpdir/err.log" || true

# Existing newer content must remain.
content=$(cat "$tmpdir/out/data.txt")
[[ "$content" == 'existing-newer' ]] || { printf 'expected existing newer to remain, got: %s\n' "$content" >&2; exit 1; }
