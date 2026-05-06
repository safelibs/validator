#!/usr/bin/env bash
# @testcase: usage-gio-r10-info-unix-nlink-hardlink
# @title: gio info reports unix::nlink incremented after hardlink
# @description: Creates a regular file, hardlinks it, and verifies "gio info -a unix::nlink" reports 2 for both names.
# @timeout: 60
# @tags: usage, gio, info, unix
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'data\n' >"$tmpdir/orig.txt"
ln "$tmpdir/orig.txt" "$tmpdir/hardlink.txt"
gio info -a unix::nlink "$tmpdir/orig.txt" >"$tmpdir/orig.out"
gio info -a unix::nlink "$tmpdir/hardlink.txt" >"$tmpdir/link.out"
grep -E 'unix::nlink:[[:space:]]*2' "$tmpdir/orig.out" >/dev/null
grep -E 'unix::nlink:[[:space:]]*2' "$tmpdir/link.out" >/dev/null
