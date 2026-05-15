#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-r20-bsdtar-cf-zst-magic-header
# @title: bsdtar --zstd produces an archive whose first four bytes are the zstd frame magic
# @description: Builds a tar.zst archive via bsdtar --zstd and asserts the first four bytes of the output equal the canonical zstd frame magic 28 b5 2f fd (little-endian), pinning libarchive's zstd writer's frame-magic emission on Ubuntu 24.04.
# @timeout: 60
# @tags: usage, archive, bsdtar, zstd, magic, r20
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/src"
mkdir -p "$src"
echo "r20 magic payload" >"$src/p.txt"

(cd "$src" && bsdtar --zstd -cf "$tmpdir/out.tar.zst" p.txt)
[[ -s "$tmpdir/out.tar.zst" ]]

hex=$(head -c 4 "$tmpdir/out.tar.zst" | od -An -tx1 | tr -d ' \n')
[[ "$hex" == "28b52ffd" ]] || { printf 'expected magic 28b52ffd, got %s\n' "$hex" >&2; exit 1; }
