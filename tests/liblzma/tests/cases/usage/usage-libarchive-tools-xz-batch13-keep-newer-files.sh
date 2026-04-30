#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-batch13-keep-newer-files
# @title: bsdtar -x --keep-newer-files xz
# @description: Extracts a tar.xz over an existing newer file with --keep-newer-files; the on-disk newer file must survive while a missing peer is created.
# @timeout: 180
# @tags: usage, archive, xz
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in" "$tmpdir/out"

# Archive members carry a 2020 mtime.
printf 'archive alpha (2020)\n' >"$tmpdir/in/alpha.txt"
printf 'archive beta (2020)\n' >"$tmpdir/in/beta.txt"
touch -d '2020-01-02T00:00:00Z' "$tmpdir/in/alpha.txt" "$tmpdir/in/beta.txt"

bsdtar -cJf "$tmpdir/a.tar.xz" -C "$tmpdir/in" alpha.txt beta.txt

# .xz magic
magic_hex=$(head -c 6 "$tmpdir/a.tar.xz" | od -An -tx1 | tr -d ' \n')
test "$magic_hex" = "fd377a585a00"

# Existing on-disk alpha is newer (2024). beta does not exist on disk yet.
printf 'on-disk newer alpha (2024)\n' >"$tmpdir/out/alpha.txt"
touch -d '2024-06-01T00:00:00Z' "$tmpdir/out/alpha.txt"
sha_existing=$(sha256sum "$tmpdir/out/alpha.txt" | awk '{print $1}')

bsdtar -xf "$tmpdir/a.tar.xz" --keep-newer-files -C "$tmpdir/out"

# alpha must be untouched (the on-disk copy is newer than archive entry)
sha_after=$(sha256sum "$tmpdir/out/alpha.txt" | awk '{print $1}')
test "$sha_existing" = "$sha_after"

# beta did not exist on disk so it must be created from the archive
test -f "$tmpdir/out/beta.txt"
cmp "$tmpdir/in/beta.txt" "$tmpdir/out/beta.txt"
