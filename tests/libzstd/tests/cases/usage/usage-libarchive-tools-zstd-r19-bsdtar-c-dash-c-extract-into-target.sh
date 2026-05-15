#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-r19-bsdtar-c-dash-c-extract-into-target
# @title: bsdtar -x -f archive.tar.zst -C target extracts into the named destination directory
# @description: Builds a tar.zst archive containing payload.txt, creates a separate destination directory, runs bsdtar -xf -C dest, and asserts the member lands under dest/payload.txt with byte-identical SHA-256 to the source.
# @timeout: 60
# @tags: usage, archive, bsdtar, zstd, dash-c, r19
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/src"
mkdir -p "$src"
python3 -c 'import sys
sys.stdout.buffer.write(b"r19 dash-c payload\n" * 64)' >"$src/payload.txt"
src_sha=$(sha256sum "$src/payload.txt" | awk '{print $1}')

(cd "$src" && bsdtar --zstd -cf "$tmpdir/archive.tar.zst" payload.txt)

dest="$tmpdir/dest"
mkdir -p "$dest"
bsdtar -xf "$tmpdir/archive.tar.zst" -C "$dest"

validator_require_file "$dest/payload.txt"
out_sha=$(sha256sum "$dest/payload.txt" | awk '{print $1}')
[[ "$out_sha" == "$src_sha" ]] || { printf 'sha mismatch: src=%s out=%s\n' "$src_sha" "$out_sha" >&2; exit 1; }
