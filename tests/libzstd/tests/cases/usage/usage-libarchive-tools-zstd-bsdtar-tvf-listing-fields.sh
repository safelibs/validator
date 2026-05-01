#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-bsdtar-tvf-listing-fields
# @title: bsdtar -tvf zst archive shows mode and size fields
# @description: Creates a zstd-compressed tar with bsdtar containing a known regular file, runs bsdtar -tvf and asserts the verbose listing carries a regular-file mode prefix, the literal byte size of the input, and the member basename so the libzstd-backed listing pipeline is exercised end to end.
# @timeout: 180
# @tags: usage, archive, zstd, bsdtar, listing
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in"
python3 -c 'import sys
sys.stdout.buffer.write(b"tvf listing payload\n" * 200)' >"$tmpdir/in/notes.txt"
chmod 0644 "$tmpdir/in/notes.txt"
src_size=$(stat -c %s "$tmpdir/in/notes.txt")

bsdtar --zstd -cf "$tmpdir/a.tar.zst" -C "$tmpdir/in" notes.txt
validator_require_file "$tmpdir/a.tar.zst"

magic=$(od -An -N4 -tx1 "$tmpdir/a.tar.zst" | tr -d ' \n')
test "$magic" = "28b52ffd"

bsdtar -tvf "$tmpdir/a.tar.zst" >"$tmpdir/list.txt"
# Regular file mode prefix and size and member name must all appear on one line.
grep -E "^-rw-r--r--.* ${src_size} .* notes\\.txt$" "$tmpdir/list.txt" >/dev/null
