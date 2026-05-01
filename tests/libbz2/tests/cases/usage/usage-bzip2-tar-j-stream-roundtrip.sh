#!/usr/bin/env bash
# @testcase: usage-bzip2-tar-j-stream-roundtrip
# @title: tar -j round-trips through bzip2
# @description: Creates a bzip2-compressed tarball with tar -cjf and extracts it with tar -xjf, verifying every member's bytes match the originals.
# @timeout: 240
# @tags: usage, bzip2, tar
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/src"
printf 'first member contents\n' >"$tmpdir/src/a.txt"
printf 'second member with newlines\nline two\nline three\n' >"$tmpdir/src/b.txt"
python3 -c 'import sys
for i in range(2000):
    sys.stdout.write(f"member three row {i:05d}\n")' >"$tmpdir/src/c.txt"

orig_a=$(sha256sum "$tmpdir/src/a.txt" | awk '{print $1}')
orig_b=$(sha256sum "$tmpdir/src/b.txt" | awk '{print $1}')
orig_c=$(sha256sum "$tmpdir/src/c.txt" | awk '{print $1}')

# tar uses the bzip2 binary to produce a .tar.bz2 stream.
tar -C "$tmpdir/src" -cjf "$tmpdir/out.tar.bz2" a.txt b.txt c.txt

# The produced archive must be a valid bzip2 stream.
bzip2 -t "$tmpdir/out.tar.bz2"
file "$tmpdir/out.tar.bz2" >"$tmpdir/file.out"
validator_assert_contains "$tmpdir/file.out" 'bzip2 compressed data'

mkdir -p "$tmpdir/dst"
tar -C "$tmpdir/dst" -xjf "$tmpdir/out.tar.bz2"

new_a=$(sha256sum "$tmpdir/dst/a.txt" | awk '{print $1}')
new_b=$(sha256sum "$tmpdir/dst/b.txt" | awk '{print $1}')
new_c=$(sha256sum "$tmpdir/dst/c.txt" | awk '{print $1}')

[[ "$orig_a" == "$new_a" ]] || { printf 'a.txt sha mismatch\n' >&2; exit 1; }
[[ "$orig_b" == "$new_b" ]] || { printf 'b.txt sha mismatch\n' >&2; exit 1; }
[[ "$orig_c" == "$new_c" ]] || { printf 'c.txt sha mismatch\n' >&2; exit 1; }
