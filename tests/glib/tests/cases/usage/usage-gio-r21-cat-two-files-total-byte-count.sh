#!/usr/bin/env bash
# @testcase: usage-gio-r21-cat-two-files-total-byte-count
# @title: gio cat on two files concatenates payloads and stdout byte count equals the sum
# @description: Writes two files of sizes 100 and 250 bytes in tmpdir, runs gio cat with both as arguments, and asserts the captured stdout is exactly 350 bytes total (the sum of the two file sizes), exercising the multi-file concatenation byte-count invariant of gio cat distinct from prior single-file and multiple-filenames-only presence tests.
# @timeout: 60
# @tags: usage, gio, cat, concat, r21
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 -c 'import sys; sys.stdout.buffer.write(b"A" * 100)' >"$tmpdir/a.dat"
python3 -c 'import sys; sys.stdout.buffer.write(b"B" * 250)' >"$tmpdir/b.dat"

gio cat "$tmpdir/a.dat" "$tmpdir/b.dat" >"$tmpdir/out.bin"

size=$(stat -c '%s' "$tmpdir/out.bin")
[[ "$size" == "350" ]] || { printf 'expected 350 bytes, got %s\n' "$size" >&2; exit 1; }

# Sanity: first 100 bytes are 'A', remaining 250 are 'B'.
head -c 100 "$tmpdir/out.bin" >"$tmpdir/head.bin"
tail -c 250 "$tmpdir/out.bin" >"$tmpdir/tail.bin"
python3 -c 'import sys; assert open("'"$tmpdir/head.bin"'", "rb").read() == b"A" * 100'
python3 -c 'import sys; assert open("'"$tmpdir/tail.bin"'", "rb").read() == b"B" * 250'
