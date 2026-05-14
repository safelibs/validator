#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-r18-bsdtar-exclude-pattern-skips-member
# @title: bsdtar --zstd --exclude omits matching paths during tar.zst creation
# @description: Packs three files into tar.zst while passing --exclude 'skip.txt' to bsdtar, lists the resulting archive, and asserts the excluded member is absent while the other members remain.
# @timeout: 60
# @tags: usage, archive, bsdtar, zstd, exclude, r18
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/src"
mkdir -p "$src"
printf 'k\n' >"$src/keep1.txt"
printf 'k\n' >"$src/keep2.txt"
printf 's\n' >"$src/skip.txt"

(cd "$src" && bsdtar --zstd --exclude 'skip.txt' -cf "$tmpdir/archive.tar.zst" keep1.txt keep2.txt skip.txt)
bsdtar -tf "$tmpdir/archive.tar.zst" >"$tmpdir/listing.txt"

validator_assert_contains "$tmpdir/listing.txt" 'keep1.txt'
validator_assert_contains "$tmpdir/listing.txt" 'keep2.txt'
if grep -q 'skip.txt' "$tmpdir/listing.txt"; then
    echo "expected 'skip.txt' to be excluded" >&2
    cat "$tmpdir/listing.txt" >&2
    exit 1
fi
