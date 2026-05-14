#!/usr/bin/env bash
# @testcase: usage-bzip2-r18-bunzip2-leaves-mode-644
# @title: bunzip2 preserves the standard 0644 file mode after decompression
# @description: Creates an input file explicitly chmod 644, compresses it with bzip2, decompresses with bunzip2, and asserts the recovered file has mode 644 — locking in unix mode preservation across the compress/decompress roundtrip on noble.
# @timeout: 30
# @tags: usage, bunzip2, mode, r18
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'mode-test\n' >"$tmpdir/f.txt"
chmod 644 "$tmpdir/f.txt"

bzip2 "$tmpdir/f.txt"
bunzip2 "$tmpdir/f.txt.bz2"

mode=$(stat -c '%a' "$tmpdir/f.txt")
[[ "$mode" == "644" ]] || {
    printf 'expected mode 644, got %s\n' "$mode" >&2
    exit 1
}
