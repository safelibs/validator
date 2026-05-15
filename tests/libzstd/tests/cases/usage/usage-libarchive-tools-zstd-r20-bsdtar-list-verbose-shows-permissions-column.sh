#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-r20-bsdtar-list-verbose-shows-permissions-column
# @title: bsdtar --zstd -tvf prints a permission string column for each archive member
# @description: Builds a tar.zst archive with a single file, runs bsdtar --zstd -tvf and asserts the verbose listing's first column starts with a 'rwx'-style permission descriptor matching ^[-d][rwx-]{9}, pinning bsdtar's verbose-list permission column under zstd archives.
# @timeout: 60
# @tags: usage, archive, bsdtar, zstd, verbose-list, permissions, r20
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/src"
mkdir -p "$src"
echo "r20 perms" >"$src/payload.txt"
chmod 0644 "$src/payload.txt"

(cd "$src" && bsdtar --zstd -cf "$tmpdir/out.tar.zst" payload.txt)

bsdtar --zstd -tvf "$tmpdir/out.tar.zst" >"$tmpdir/list.txt"
[[ -s "$tmpdir/list.txt" ]]
# First column of each line should be a 10-char rwx mode descriptor.
first_col=$(awk 'NR==1 {print $1}' "$tmpdir/list.txt")
[[ "$first_col" =~ ^[-d][-rwxXsSt]{9}$ ]] || {
    printf 'unexpected permission column: %q\n' "$first_col" >&2
    cat "$tmpdir/list.txt" >&2
    exit 1
}
