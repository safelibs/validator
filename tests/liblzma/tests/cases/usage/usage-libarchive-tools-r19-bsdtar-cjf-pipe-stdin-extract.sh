#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-r19-bsdtar-cjf-pipe-stdin-extract
# @title: bsdtar piped tar.xz to bsdtar -xf - extracts payload byte-for-byte
# @description: Pipes bsdtar -cJf - through bsdtar -xf - into a destination directory and asserts the extracted file SHA-256 matches the source, exercising in-memory streaming tar.xz creation and extraction.
# @timeout: 60
# @tags: usage, bsdtar, xz, pipe, r19
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir "$tmpdir/src" "$tmpdir/dst"
python3 -c "import sys; sys.stdout.buffer.write(b'r19-pipe-stream-' * 200)" >"$tmpdir/src/data.bin"
src_sha=$(sha256sum "$tmpdir/src/data.bin" | awk '{print $1}')

(cd "$tmpdir/src" && bsdtar -cJf - data.bin) | (cd "$tmpdir/dst" && bsdtar -xf -)

[[ -f "$tmpdir/dst/data.bin" ]] || { printf 'expected extracted file\n' >&2; exit 1; }
dst_sha=$(sha256sum "$tmpdir/dst/data.bin" | awk '{print $1}')
[[ "$src_sha" == "$dst_sha" ]]
