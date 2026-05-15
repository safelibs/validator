#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-r20-xz-quiet-twice-suppresses-test-corrupt-stderr
# @title: xz -t -qq on a corrupted .xz exits non-zero with empty stderr
# @description: Compresses a payload via xz, deliberately corrupts a mid-stream byte, runs xz -t -qq on the corrupted file capturing stderr, and asserts the exit status is non-zero while stderr is empty, pinning the double-quiet flag's error suppression even on integrity failure.
# @timeout: 60
# @tags: usage, xz, test, quiet, corrupt, r20
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'r20 xz quiet corrupt payload r20 xz quiet corrupt payload\n' >"$tmpdir/in.txt"
xz -c "$tmpdir/in.txt" >"$tmpdir/in.xz"

# Corrupt a byte in the middle of the stream (well past the header)
python3 -c "
import sys
p = sys.argv[1]
data = bytearray(open(p, 'rb').read())
i = len(data) // 2
data[i] ^= 0xff
open(p, 'wb').write(data)
" "$tmpdir/in.xz"

set +e
xz -t -qq "$tmpdir/in.xz" >"$tmpdir/out.txt" 2>"$tmpdir/err.txt"
rc=$?
set -e

[[ "$rc" -ne 0 ]] || { printf 'expected nonzero exit, got %s\n' "$rc" >&2; exit 1; }
err_size=$(wc -c <"$tmpdir/err.txt")
[[ "$err_size" -eq 0 ]] || { printf 'expected empty stderr, got %s bytes\n' "$err_size" >&2; cat "$tmpdir/err.txt" >&2; exit 1; }
