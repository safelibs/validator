#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-tvf-permissions-listing
# @title: bsdtar zstd verbose listing shows permission columns
# @description: Lists a zstd-compressed tar with bsdtar -tvf and verifies the verbose listing exposes the standard ten-column permission string plus the archived filename for each member.
# @timeout: 180
# @tags: usage, archive, zstd
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in"
printf 'rwxr payload\n' >"$tmpdir/in/exec.sh"
printf 'plain payload\n' >"$tmpdir/in/data.txt"
chmod 755 "$tmpdir/in/exec.sh"
chmod 644 "$tmpdir/in/data.txt"

bsdtar --zstd -cf "$tmpdir/a.tar.zst" -C "$tmpdir/in" exec.sh data.txt
validator_require_file "$tmpdir/a.tar.zst"

magic=$(od -An -N4 -tx1 "$tmpdir/a.tar.zst" | tr -d ' \n')
test "$magic" = "28b52ffd"

bsdtar -tvf "$tmpdir/a.tar.zst" >"$tmpdir/list"

validator_assert_contains "$tmpdir/list" 'exec.sh'
validator_assert_contains "$tmpdir/list" 'data.txt'

# bsdtar verbose listing renders mode columns identical to GNU tar's "ls -l".
grep -Eq '^-rwxr-xr-x .* exec\.sh$' "$tmpdir/list"
grep -Eq '^-rw-r--r-- .* data\.txt$' "$tmpdir/list"
