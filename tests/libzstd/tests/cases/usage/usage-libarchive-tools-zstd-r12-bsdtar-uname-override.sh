#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-r12-bsdtar-uname-override
# @title: bsdtar --zstd --uname/--gname rewrite the recorded owner labels
# @description: Creates a small file, archives it with bsdtar --zstd plus --uname=root and --gname=root to force the owner labels in the archive header, and asserts the verbose listing shows the requested owner/group names regardless of the calling user.
# @timeout: 120
# @tags: usage, archive, zstd, bsdtar, owner
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in"
printf 'uname-override body\n' >"$tmpdir/in/file.txt"

bsdtar --zstd --uname=root --gname=root \
    -cf "$tmpdir/out.tar.zst" -C "$tmpdir/in" file.txt

bsdtar -tvf "$tmpdir/out.tar.zst" >"$tmpdir/listing"

# The verbose tvf line for file.txt must show root as the owner and group columns
# (bsdtar 3.x prints them as separate space-padded fields, e.g. "root   root").
grep -E '[[:space:]]root[[:space:]]+root[[:space:]]' "$tmpdir/listing" >/dev/null || {
    printf 'expected root owner and root group labels in tvf listing\n' >&2
    cat "$tmpdir/listing" >&2
    exit 1
}
