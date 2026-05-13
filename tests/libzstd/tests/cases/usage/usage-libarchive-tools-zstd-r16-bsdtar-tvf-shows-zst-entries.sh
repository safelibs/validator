#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-r16-bsdtar-tvf-shows-zst-entries
# @title: bsdtar -tvf on a tar.zst archive lists the expected member paths under verbose long-form listing
# @description: Packs two files into a tar.zst archive with bsdtar --zstd, runs bsdtar -tvf to list it, and asserts the verbose output includes both member relative paths and the canonical zst-content prefix is parsed (member count == 2 excluding directory entries).
# @timeout: 60
# @tags: usage, archive, zstd, bsdtar, listing
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/src"
mkdir -p "$src"
python3 -c 'import sys
sys.stdout.buffer.write(b"r16 tvf entry alpha row\n" * 40)' >"$src/alpha.txt"
python3 -c 'import sys
sys.stdout.buffer.write(b"r16 tvf entry bravo row\n" * 50)' >"$src/bravo.txt"

(cd "$src" && bsdtar --zstd -cf "$tmpdir/archive.tar.zst" alpha.txt bravo.txt)
validator_require_file "$tmpdir/archive.tar.zst"

bsdtar -tvf "$tmpdir/archive.tar.zst" >"$tmpdir/listing.txt"
[[ -s "$tmpdir/listing.txt" ]]

validator_assert_contains "$tmpdir/listing.txt" 'alpha.txt'
validator_assert_contains "$tmpdir/listing.txt" 'bravo.txt'

# Count regular file entries (lines starting with '-').
files=$(grep -cE '^-' "$tmpdir/listing.txt" || true)
[[ "$files" == "2" ]] || {
    printf 'expected 2 regular-file entries in -tvf listing, got %s\n' "$files" >&2
    cat "$tmpdir/listing.txt" >&2
    exit 1
}
