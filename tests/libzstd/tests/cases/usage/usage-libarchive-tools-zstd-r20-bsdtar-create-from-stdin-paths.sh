#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-r20-bsdtar-create-from-stdin-paths
# @title: bsdtar --zstd -T - reads member paths from stdin to build a multi-file archive
# @description: Pipes two newline-separated paths to bsdtar --zstd -cf out.tar.zst -T -, then lists the archive contents and asserts both names appear exactly once each in the listing — pinning libarchive's stdin-file-list (-T -) path under zstd compression.
# @timeout: 60
# @tags: usage, archive, bsdtar, zstd, stdin-filelist, r20
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/src"
mkdir -p "$src"
echo "alpha" >"$src/a.txt"
echo "beta" >"$src/b.txt"

(cd "$src" && printf '%s\n' a.txt b.txt | bsdtar --zstd -cf "$tmpdir/out.tar.zst" -T -)

bsdtar --zstd -tf "$tmpdir/out.tar.zst" >"$tmpdir/list.txt"
a_count=$(grep -cx 'a.txt' "$tmpdir/list.txt" || true)
b_count=$(grep -cx 'b.txt' "$tmpdir/list.txt" || true)
[[ "$a_count" == "1" ]] || { echo "expected exactly one a.txt entry, got $a_count" >&2; cat "$tmpdir/list.txt" >&2; exit 1; }
[[ "$b_count" == "1" ]] || { echo "expected exactly one b.txt entry, got $b_count" >&2; cat "$tmpdir/list.txt" >&2; exit 1; }
