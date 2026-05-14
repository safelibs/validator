#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-r18-bsdtar-pipe-stdin-extract-stdout
# @title: bsdtar -O reads a tar.zst from stdin and writes member content to stdout
# @description: Creates a tar.zst archive with a single member, feeds it to bsdtar -O via stdin, and asserts the SHA-256 of the stdout stream matches the original file's SHA-256 to pin the libarchive stdin-to-stdout extraction path.
# @timeout: 60
# @tags: usage, archive, bsdtar, zstd, stdin, r18
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/src"
mkdir -p "$src"
python3 -c 'import sys
sys.stdout.buffer.write(b"r18 stdin-pipe payload\n" * 50)' >"$src/payload.txt"
src_sha=$(sha256sum "$src/payload.txt" | awk '{print $1}')

(cd "$src" && bsdtar --zstd -cf "$tmpdir/archive.tar.zst" payload.txt)

streamed_sha=$(bsdtar -xOf - <"$tmpdir/archive.tar.zst" | sha256sum | awk '{print $1}')
[[ "$streamed_sha" == "$src_sha" ]] || {
    printf 'sha mismatch: src=%s streamed=%s\n' "$src_sha" "$streamed_sha" >&2
    exit 1
}
