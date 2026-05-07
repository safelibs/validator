#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-r15-bsdtar-uname-gname-override
# @title: bsdtar --uname/--gname override the symbolic owner/group recorded in a zstd tar
# @description: Builds a zstd-compressed tar with bsdtar --uname/--gname pointing at synthetic identifiers, lists the archive with -tvf, and asserts each entry's owner/group columns reflect the supplied overrides rather than the host's runtime user/group.
# @timeout: 60
# @tags: usage, archive, bsdtar, ownership
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/src"
mkdir -p "$src"
printf 'r15 uname-gname override file\n' >"$src/a.txt"

archive="$tmpdir/out.tar.zst"
bsdtar --uname r15user --gname r15group --zstd -cf "$archive" -C "$tmpdir" src
validator_require_file "$archive"

bsdtar -tvf "$archive" >"$tmpdir/listing"

# Each entry must carry the supplied uname/gname pair.
grep -E 'r15user[[:space:]]+r15group' "$tmpdir/listing" >/dev/null || {
    printf 'expected r15user/r15group ownership in listing\n' >&2
    cat "$tmpdir/listing" >&2
    exit 1
}

# Sanity: the file member is present.
grep -q 'src/a\.txt' "$tmpdir/listing"
