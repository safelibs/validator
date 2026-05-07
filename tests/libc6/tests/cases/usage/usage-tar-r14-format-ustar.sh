#!/usr/bin/env bash
# @testcase: usage-tar-r14-format-ustar
# @title: tar --format=ustar produces a USTAR-magic archive header
# @description: Creates a single-member archive with tar --format=ustar under LC_ALL=C, asserts the archive lists that member, and asserts the tar header at offset 257 contains the canonical "ustar" magic string (no PAX extension, plain USTAR format).
# @timeout: 60
# @tags: usage, tar, format, ustar
# @client: tar

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/src"
printf 'r14 ustar payload\n' >"$tmpdir/src/file.txt"

LC_ALL=C tar --format=ustar -C "$tmpdir" -cf "$tmpdir/out.tar" src/file.txt

# Archive lists the expected member.
LC_ALL=C tar -tf "$tmpdir/out.tar" >"$tmpdir/list.txt"
LC_ALL=C grep -Fxq 'src/file.txt' "$tmpdir/list.txt"

# USTAR magic at byte offset 257 of the first header block.
# 'ustar\0' (6 bytes, NUL-terminated) per POSIX 1003.1-1988 ustar.
magic=$(LC_ALL=C dd if="$tmpdir/out.tar" bs=1 skip=257 count=5 status=none)
[[ "$magic" == "ustar" ]]
