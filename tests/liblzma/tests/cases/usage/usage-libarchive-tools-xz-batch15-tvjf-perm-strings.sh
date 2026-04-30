#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-batch15-tvjf-perm-strings
# @title: bsdtar -tvJf prints perm strings on tar.xz
# @description: Builds a tar.xz with three files of distinct mode bits and verifies bsdtar -tvJf surfaces matching perm strings for each entry, exercising the explicit -J flag on the verbose listing path.
# @timeout: 180
# @tags: usage, archive, xz
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in"
printf '#!/bin/sh\n: ok\n' >"$tmpdir/in/run.sh"
printf 'data row\n'        >"$tmpdir/in/data.txt"
printf 'private row\n'     >"$tmpdir/in/secret.txt"
chmod 755 "$tmpdir/in/run.sh"
chmod 644 "$tmpdir/in/data.txt"
chmod 600 "$tmpdir/in/secret.txt"

bsdtar -cJf "$tmpdir/a.tar.xz" -C "$tmpdir/in" run.sh data.txt secret.txt

magic_hex=$(head -c 6 "$tmpdir/a.tar.xz" | od -An -tx1 | tr -d ' \n')
test "$magic_hex" = "fd377a585a00"

# Use -tvJf explicitly so the J flag drives the decompression path on listing.
bsdtar -tvJf "$tmpdir/a.tar.xz" >"$tmpdir/list.txt"

# Exact entry count.
test "$(wc -l <"$tmpdir/list.txt")" -eq 3

# Each row must start with the matching perm string for that file.
grep -Eq '^-rwxr-xr-x .* run\.sh$'    "$tmpdir/list.txt"
grep -Eq '^-rw-r--r-- .* data\.txt$'  "$tmpdir/list.txt"
grep -Eq '^-rw------- .* secret\.txt$' "$tmpdir/list.txt"
