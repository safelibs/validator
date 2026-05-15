#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-r20-bsdtar-x-creates-target-dir
# @title: bsdtar --zstd -x recreates a directory-only archive entry on extraction
# @description: Builds a tar.zst archive containing a directory entry named adir/, extracts it into a fresh destination via bsdtar --zstd -xf, and asserts the destination contains adir as a real directory — pinning libarchive's zstd-driven directory-entry materialization.
# @timeout: 60
# @tags: usage, archive, bsdtar, zstd, directory-entry, r20
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/src"
mkdir -p "$src/adir"

(cd "$src" && bsdtar --zstd -cf "$tmpdir/out.tar.zst" adir)

dest="$tmpdir/dest"
mkdir -p "$dest"
(cd "$dest" && bsdtar --zstd -xf "$tmpdir/out.tar.zst")

[[ -d "$dest/adir" ]] || { echo "expected adir to exist as a directory under $dest" >&2; ls -la "$dest" >&2; exit 1; }
