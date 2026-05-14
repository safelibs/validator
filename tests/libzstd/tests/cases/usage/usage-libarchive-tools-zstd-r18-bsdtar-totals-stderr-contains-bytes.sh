#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-r18-bsdtar-totals-stderr-contains-bytes
# @title: bsdtar --zstd --totals emits a final byte count summary to stderr
# @description: Packs a small payload into tar.zst with bsdtar --zstd --totals, captures stderr, and asserts the totals summary line mentions 'bytes' to confirm the libarchive totals reporting path is reached when the zstd filter is in use.
# @timeout: 60
# @tags: usage, archive, bsdtar, zstd, totals, r18
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/src"
mkdir -p "$src"
python3 -c 'import sys
sys.stdout.buffer.write(b"r18 totals row\n" * 40)' >"$src/t.txt"

(cd "$src" && bsdtar --zstd --totals -cf "$tmpdir/archive.tar.zst" t.txt) 2>"$tmpdir/err.log"
validator_require_file "$tmpdir/archive.tar.zst"
test -s "$tmpdir/archive.tar.zst"

grep -iq 'byte' "$tmpdir/err.log" || {
    echo "expected totals summary mentioning bytes" >&2
    cat "$tmpdir/err.log" >&2
    exit 1
}
