#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-r9-bsdtar-strip-components
# @title: bsdtar zstd extract --strip-components
# @description: Archives a nested directory tree with bsdtar --zstd and extracts with --strip-components=1, asserting the top-level prefix is removed in the output.
# @timeout: 180
# @tags: usage, archive, zstd
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in/top/sub" "$tmpdir/out"
printf 'leaf payload\n' >"$tmpdir/in/top/sub/leaf.txt"

bsdtar --zstd -cf "$tmpdir/a.tar.zst" -C "$tmpdir/in" top
bsdtar -xf "$tmpdir/a.tar.zst" -C "$tmpdir/out" --strip-components=1

[[ -f "$tmpdir/out/sub/leaf.txt" ]] || { echo "missing extracted leaf" >&2; ls -R "$tmpdir/out" >&2; exit 1; }
[[ ! -d "$tmpdir/out/top" ]] || { echo "top should be stripped" >&2; exit 1; }
diff -q "$tmpdir/in/top/sub/leaf.txt" "$tmpdir/out/sub/leaf.txt"
