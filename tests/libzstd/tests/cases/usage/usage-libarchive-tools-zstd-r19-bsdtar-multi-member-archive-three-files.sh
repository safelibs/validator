#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-r19-bsdtar-multi-member-archive-three-files
# @title: bsdtar packs three named files into one tar.zst and extracts them with matching SHA-256 each
# @description: Creates three small files with distinct payloads, packs them together into a single tar.zst, extracts to a fresh directory, and asserts every extracted file's SHA-256 equals its source — pinning the libarchive multi-member tar.zst roundtrip path.
# @timeout: 60
# @tags: usage, archive, bsdtar, zstd, multi-member, r19
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/src"
mkdir -p "$src"
python3 -c 'import sys; sys.stdout.buffer.write(b"AAA\n" * 16)' >"$src/a.txt"
python3 -c 'import sys; sys.stdout.buffer.write(b"BBBBB\n" * 24)' >"$src/b.txt"
python3 -c 'import sys; sys.stdout.buffer.write(b"CC\n" * 8)' >"$src/c.txt"

declare -A sums
for name in a.txt b.txt c.txt; do
    sums[$name]=$(sha256sum "$src/$name" | awk '{print $1}')
done

(cd "$src" && bsdtar --zstd -cf "$tmpdir/archive.tar.zst" a.txt b.txt c.txt)
validator_require_file "$tmpdir/archive.tar.zst"

dest="$tmpdir/dest"
mkdir -p "$dest"
(cd "$dest" && bsdtar -xf "$tmpdir/archive.tar.zst")

for name in a.txt b.txt c.txt; do
    out_sha=$(sha256sum "$dest/$name" | awk '{print $1}')
    [[ "$out_sha" == "${sums[$name]}" ]] || {
        printf 'sha mismatch for %s: src=%s out=%s\n' "$name" "${sums[$name]}" "$out_sha" >&2
        exit 1
    }
done
