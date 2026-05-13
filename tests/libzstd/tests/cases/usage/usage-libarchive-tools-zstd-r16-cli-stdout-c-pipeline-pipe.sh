#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-r16-cli-stdout-c-pipeline-pipe
# @title: zstd -c | zstd -dc pipeline round-trips a source payload through stdin/stdout
# @description: Pipes a generated payload through zstd -c (compress to stdout) into zstd -dc (decompress from stdin to stdout), captures the result, and asserts the SHA-256 of the decompressed bytes equals the SHA-256 of the source — exercising the streaming stdout/stdin pipeline.
# @timeout: 60
# @tags: usage, archive, zstd, cli, pipeline
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/payload.bin"
python3 -c 'import sys
sys.stdout.buffer.write(b"r16 stdout-pipeline payload row\n" * 800)' >"$src"
src_sum=$(sha256sum "$src" | awk '{print $1}')

zstd -cq "$src" | zstd -dcq >"$tmpdir/decoded.bin"
test "$(sha256sum "$tmpdir/decoded.bin" | awk '{print $1}')" = "$src_sum"
