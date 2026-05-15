#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-r20-xz-verbose-stderr-mentions-ratio
# @title: xz -v compression of a non-trivial payload emits a non-empty stderr summary
# @description: Compresses a 4 KiB pseudo-random payload via xz -v -c capturing stderr to a tempfile, then asserts the stderr capture is non-empty (xz emits a single-file progress/summary line in verbose mode) while the captured stdout is a valid .xz that decompresses back to the original SHA-256.
# @timeout: 60
# @tags: usage, xz, verbose, stderr, r20
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 -c "import sys; sys.stdout.buffer.write(bytes((i * 53 + 7) & 0xff for i in range(4096)))" >"$tmpdir/in.bin"
src_sha=$(sha256sum "$tmpdir/in.bin" | awk '{print $1}')

xz -v -c "$tmpdir/in.bin" >"$tmpdir/in.xz" 2>"$tmpdir/err.txt"
err_size=$(wc -c <"$tmpdir/err.txt")
[[ "$err_size" -gt 0 ]] || { printf 'expected non-empty stderr in verbose mode\n' >&2; exit 1; }

xz -dc "$tmpdir/in.xz" >"$tmpdir/out.bin"
dst_sha=$(sha256sum "$tmpdir/out.bin" | awk '{print $1}')
[[ "$src_sha" == "$dst_sha" ]] || { printf 'sha mismatch %s vs %s\n' "$src_sha" "$dst_sha" >&2; exit 1; }
