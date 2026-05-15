#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-r20-bsdtar-q-quiet-stops-after-first-match
# @title: bsdtar --zstd -xq stops extracting after the first named member is found
# @description: Builds a tar.zst archive containing two files (a.txt and b.txt), extracts only a.txt with bsdtar --zstd -xqf using -q (fast-quit) and the explicit member name, and asserts a.txt was extracted while b.txt was not — pinning the libarchive zstd reader's fast-quit name match path.
# @timeout: 60
# @tags: usage, archive, bsdtar, zstd, fast-quit, r20
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/src"
mkdir -p "$src"
echo "first" >"$src/a.txt"
echo "second" >"$src/b.txt"

(cd "$src" && bsdtar --zstd -cf "$tmpdir/out.tar.zst" a.txt b.txt)

dest="$tmpdir/dest"
mkdir -p "$dest"
(cd "$dest" && bsdtar --zstd -xqf "$tmpdir/out.tar.zst" a.txt)

[[ -f "$dest/a.txt" ]] || { echo "expected a.txt to be extracted" >&2; ls -la "$dest" >&2; exit 1; }
if [[ -f "$dest/b.txt" ]]; then
    echo "expected b.txt to be skipped under -q" >&2
    ls -la "$dest" >&2
    exit 1
fi
