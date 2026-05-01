#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-batch19-tv-directory-entry
# @title: bsdtar -tvJf shows directory and file rows
# @description: Builds a tar.xz containing a directory plus enclosed files and confirms bsdtar -tvJf prints both a leading 'd' row for the directory and '-' rows for the files, exercising the verbose listing path on top of liblzma decompression.
# @timeout: 180
# @tags: usage, archive, xz, listing
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/src/sub"
printf 'first inside sub\n' >"$tmpdir/src/sub/one.txt"
printf 'second inside sub\n' >"$tmpdir/src/sub/two.txt"

bsdtar -cJf "$tmpdir/a.tar.xz" -C "$tmpdir/src" sub

# .xz magic
magic_hex=$(head -c 6 "$tmpdir/a.tar.xz" | od -An -tx1 | tr -d ' \n')
test "$magic_hex" = "fd377a585a00"

bsdtar -tvJf "$tmpdir/a.tar.xz" >"$tmpdir/list.txt"

# Exactly three entries: the directory and two files.
test "$(wc -l <"$tmpdir/list.txt")" -eq 3

# Directory row begins with 'd'.
grep -Eq '^d.* sub/?$' "$tmpdir/list.txt"

# File rows begin with '-' and reference the inner files.
grep -Eq '^-.* sub/one\.txt$' "$tmpdir/list.txt"
grep -Eq '^-.* sub/two\.txt$' "$tmpdir/list.txt"
