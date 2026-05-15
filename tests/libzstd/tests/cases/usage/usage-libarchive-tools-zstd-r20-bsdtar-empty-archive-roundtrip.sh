#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-r20-bsdtar-empty-archive-roundtrip
# @title: bsdtar --zstd creates an empty tar.zst archive that lists with no members
# @description: Builds a tar.zst archive from an empty file list via bsdtar --zstd -cf out.tar.zst -T /dev/null, asserts the archive is non-empty (it still has a tar terminator wrapped in a zstd frame) and that bsdtar --zstd -tf produces zero member lines, pinning libarchive's empty-archive emission under zstd.
# @timeout: 60
# @tags: usage, archive, bsdtar, zstd, empty, r20
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

bsdtar --zstd -cf "$tmpdir/out.tar.zst" -T /dev/null
[[ -s "$tmpdir/out.tar.zst" ]] || { echo "expected non-empty archive output" >&2; exit 1; }

bsdtar --zstd -tf "$tmpdir/out.tar.zst" >"$tmpdir/list.txt"
# Count non-empty lines (should be zero).
non_empty_lines=$(grep -c . "$tmpdir/list.txt" || true)
[[ "$non_empty_lines" == "0" ]] || { printf 'expected 0 listed members, got %s\n' "$non_empty_lines" >&2; cat "$tmpdir/list.txt" >&2; exit 1; }
