#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-r13-cli-no-progress-stderr-quiet
# @title: zstd CLI --no-progress suppresses the progress bar marker characters in stderr
# @description: Compresses a payload with zstd --no-progress -o, captures stderr, and asserts the carriage-return-driven progress markers (Read/Write/dictionary updates) are absent from the recorded stderr stream while the .zst output still validates.
# @timeout: 120
# @tags: usage, archive, zstd, cli, progress
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/payload.bin"
python3 -c 'import sys
sys.stdout.buffer.write(b"r13 no-progress sample row\n" * 8000)' >"$src"
validator_require_file "$src"

# --no-progress + verbose: progress markers (CR-driven Read/Write counters) must be absent.
zstd -v --no-progress -o "$tmpdir/out.zst" "$src" >"$tmpdir/stdout.log" 2>"$tmpdir/stderr.log"
validator_require_file "$tmpdir/out.zst"

# zstd's progress lines contain a literal carriage return; with --no-progress none should appear.
if grep -q $'\r' "$tmpdir/stderr.log"; then
    printf 'unexpected progress carriage return in stderr with --no-progress\n' >&2
    od -c "$tmpdir/stderr.log" | head -n 5 >&2
    exit 1
fi

magic=$(od -An -N4 -tx1 "$tmpdir/out.zst" | tr -d ' \n')
test "$magic" = "28b52ffd"
zstd -tq "$tmpdir/out.zst"
