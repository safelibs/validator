#!/usr/bin/env bash
# @testcase: usage-findutils-inum-match
# @title: find -inum locates files by inode number
# @description: Creates a file plus a hard link, queries its inode via stat, and verifies find -inum lists both names through libc filesystem stat calls.
# @timeout: 120
# @tags: usage, findutils, filesystem, libc
# @client: findutils

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-findutils-inum-match"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/tree"
printf 'payload\n' >"$tmpdir/tree/original.txt"
ln "$tmpdir/tree/original.txt" "$tmpdir/tree/hardlink.txt"
printf 'other\n' >"$tmpdir/tree/unrelated.txt"

inode=$(stat -c '%i' "$tmpdir/tree/original.txt")
test -n "$inode"

find "$tmpdir/tree" -inum "$inode" -printf '%f\n' | sort >"$tmpdir/out"

expected=$(printf 'hardlink.txt\noriginal.txt\n')
actual=$(cat "$tmpdir/out")
test "$actual" = "$expected"

# unrelated.txt has a distinct inode and must not appear.
if grep -Fxq 'unrelated.txt' "$tmpdir/out"; then exit 1; fi
