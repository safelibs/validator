#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-r16-cli-test-flag-valid-frame
# @title: zstd -t verifies the integrity of a valid frame without emitting decoded data
# @description: Compresses a payload to .zst, runs zstd -t against it (test/integrity mode), asserts exit code 0, and confirms zstd -t does not produce any decoded output on stdout — locking in the test-only contract of the -t flag on a well-formed frame.
# @timeout: 60
# @tags: usage, archive, zstd, cli, test
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/payload.bin"
python3 -c 'import sys
sys.stdout.buffer.write(b"r16 test-flag verify payload row\n" * 1000)' >"$src"

zstd -q -o "$tmpdir/out.zst" "$src"
validator_require_file "$tmpdir/out.zst"

# -t must succeed and emit no decoded bytes on stdout.
zstd -t "$tmpdir/out.zst" >"$tmpdir/stdout.bin" 2>"$tmpdir/stderr.log"
test ! -s "$tmpdir/stdout.bin" || {
    printf 'zstd -t produced unexpected stdout (%s bytes)\n' "$(wc -c <"$tmpdir/stdout.bin")" >&2
    exit 1
}
