#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-batch13-tv-verbose-perms
# @title: bsdtar -tv lists xz tar perms
# @description: Builds a tar.xz with two files of distinct mode bits and confirms bsdtar -tv prints perm strings that match the source modes.
# @timeout: 180
# @tags: usage, archive, xz
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in"
printf '#!/bin/sh\n: ok\n' >"$tmpdir/in/run.sh"
printf 'data row\n' >"$tmpdir/in/data.txt"
chmod 755 "$tmpdir/in/run.sh"
chmod 644 "$tmpdir/in/data.txt"

bsdtar -cJf "$tmpdir/a.tar.xz" -C "$tmpdir/in" run.sh data.txt

# .xz magic
magic_hex=$(head -c 6 "$tmpdir/a.tar.xz" | od -An -tx1 | tr -d ' \n')
test "$magic_hex" = "fd377a585a00"

bsdtar -tvf "$tmpdir/a.tar.xz" >"$tmpdir/list.txt"

# Exact entry count
test "$(wc -l <"$tmpdir/list.txt")" -eq 2

# Verbose listing rows: leading perm string then space then link-count etc.
grep -Eq '^-rwxr-xr-x .* run\.sh$' "$tmpdir/list.txt"
grep -Eq '^-rw-r--r-- .* data\.txt$' "$tmpdir/list.txt"
