#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-batch15-mtime-exact-roundtrip
# @title: bsdtar xz preserves mtime exactly across two distinct files
# @description: Stamps two files with two distinct deterministic mtimes, round-trips them through tar.xz, and verifies bsdtar -p restores both mtimes byte-identically.
# @timeout: 180
# @tags: usage, archive, xz
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in" "$tmpdir/out"
printf 'first payload\n'  >"$tmpdir/in/first.txt"
printf 'second payload\n' >"$tmpdir/in/second.txt"

# Two distinct deterministic timestamps so we can detect any swap or drift.
touch -d '2019-03-04T05:06:07Z' "$tmpdir/in/first.txt"
touch -d '2022-11-12T13:14:15Z' "$tmpdir/in/second.txt"

mtime_first_in=$(stat -c %Y "$tmpdir/in/first.txt")
mtime_second_in=$(stat -c %Y "$tmpdir/in/second.txt")
test "$mtime_first_in" != "$mtime_second_in"

bsdtar -cJf "$tmpdir/a.tar.xz" -C "$tmpdir/in" first.txt second.txt

magic_hex=$(head -c 6 "$tmpdir/a.tar.xz" | od -An -tx1 | tr -d ' \n')
test "$magic_hex" = "fd377a585a00"

bsdtar -xpf "$tmpdir/a.tar.xz" -C "$tmpdir/out"

mtime_first_out=$(stat -c %Y "$tmpdir/out/first.txt")
mtime_second_out=$(stat -c %Y "$tmpdir/out/second.txt")

test "$mtime_first_in"  = "$mtime_first_out"
test "$mtime_second_in" = "$mtime_second_out"

# Content must also be byte-identical so we know we are not comparing zeros.
cmp "$tmpdir/in/first.txt"  "$tmpdir/out/first.txt"
cmp "$tmpdir/in/second.txt" "$tmpdir/out/second.txt"
