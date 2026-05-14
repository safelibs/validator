#!/usr/bin/env bash
# @testcase: usage-bzip2-r18-bzcat-via-tar-stream
# @title: bzcat feeds a bzip2-compressed tar stream into tar -tf for listing
# @description: Creates three files in a directory, packs them into a tar archive, compresses the tar with bzip2, then pipes bzcat output into tar -tf and asserts each of the three member filenames appears in the listing — exercising the cli stream contract for archive consumers.
# @timeout: 60
# @tags: usage, bzcat, tar, stream, r18
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/src"
for name in alpha bravo charlie; do
    printf 'content-%s\n' "$name" >"$tmpdir/src/$name.txt"
done

cd "$tmpdir"
tar -cf src.tar src
bzip2 src.tar

[[ -f "$tmpdir/src.tar.bz2" ]] || { printf 'expected src.tar.bz2\n' >&2; exit 1; }

bzcat src.tar.bz2 | tar -tf - >"$tmpdir/listing"

for name in alpha bravo charlie; do
    validator_assert_contains "$tmpdir/listing" "src/$name.txt"
done
