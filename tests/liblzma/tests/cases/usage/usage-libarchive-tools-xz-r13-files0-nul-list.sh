#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-r13-files0-nul-list
# @title: xz --files0= reads NUL-separated filenames from a list file
# @description: Constructs a NUL-delimited list of two source paths and runs "xz --files0=list" with --keep, asserting both .xz outputs are produced and both decode back to the original sha256, exercising the NUL-separated variant of --files= alongside the newline-separated case.
# @timeout: 120
# @tags: usage, xz, files0
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in"
printf 'nul-alpha\n' >"$tmpdir/in/a.txt"
printf 'nul-beta longer payload\n' >"$tmpdir/in/b.txt"

a_sha=$(sha256sum "$tmpdir/in/a.txt" | awk '{print $1}')
b_sha=$(sha256sum "$tmpdir/in/b.txt" | awk '{print $1}')

# Build a NUL-separated list (two entries, no trailing NUL is fine for xz).
printf '%s\0%s\0' "$tmpdir/in/a.txt" "$tmpdir/in/b.txt" >"$tmpdir/list.bin"

xz --keep --files0="$tmpdir/list.bin"

[[ -f "$tmpdir/in/a.txt.xz" ]]
[[ -f "$tmpdir/in/b.txt.xz" ]]

xz -dc "$tmpdir/in/a.txt.xz" >"$tmpdir/da.txt"
xz -dc "$tmpdir/in/b.txt.xz" >"$tmpdir/db.txt"

test "$a_sha" = "$(sha256sum "$tmpdir/da.txt" | awk '{print $1}')"
test "$b_sha" = "$(sha256sum "$tmpdir/db.txt" | awk '{print $1}')"
