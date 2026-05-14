#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-r17-bsdtar-options-compression-level-five
# @title: bsdtar --zstd --options zstd:compression-level=5 produces a valid tar.zst archive
# @description: Packs two source files into a tar.zst archive with bsdtar --zstd and the explicit '--options zstd:compression-level=5' knob, then re-lists the archive and asserts both members are present, exercising libarchive's zstd compression-level option wiring.
# @timeout: 60
# @tags: usage, archive, bsdtar, zstd, options
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/src"
mkdir -p "$src"
python3 -c 'import sys
sys.stdout.buffer.write(b"r17 level5 alpha row\n" * 60)' >"$src/alpha.txt"
python3 -c 'import sys
sys.stdout.buffer.write(b"r17 level5 bravo row\n" * 80)' >"$src/bravo.txt"

(cd "$src" && bsdtar --zstd --options 'zstd:compression-level=5' -cf "$tmpdir/archive.tar.zst" alpha.txt bravo.txt)
validator_require_file "$tmpdir/archive.tar.zst"
test -s "$tmpdir/archive.tar.zst"

bsdtar -tf "$tmpdir/archive.tar.zst" >"$tmpdir/listing.txt"
validator_assert_contains "$tmpdir/listing.txt" 'alpha.txt'
validator_assert_contains "$tmpdir/listing.txt" 'bravo.txt'
