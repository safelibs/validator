#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-r18-bsdcat-tar-zst-stream-equals-source
# @title: bsdcat on a single-file tar.zst archive streams the original file contents
# @description: Creates a tar.zst archive containing a single text file, pipes the archive through bsdcat, and asserts the streamed bytes equal the original file's contents — exercising libarchive's bsdcat tar-zst stream-extract path.
# @timeout: 60
# @tags: usage, archive, bsdcat, zstd, r18
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/src"
mkdir -p "$src"
python3 -c 'import sys
sys.stdout.buffer.write(b"r18 bsdcat single-file row\n" * 32)' >"$src/payload.txt"

(cd "$src" && bsdtar --zstd -cf "$tmpdir/archive.tar.zst" payload.txt)

src_sha=$(sha256sum "$src/payload.txt" | awk '{print $1}')
streamed_sha=$(bsdcat "$tmpdir/archive.tar.zst" | sha256sum | awk '{print $1}')

[[ "$src_sha" == "$streamed_sha" ]] || {
    printf 'sha mismatch: src=%s streamed=%s\n' "$src_sha" "$streamed_sha" >&2
    exit 1
}
