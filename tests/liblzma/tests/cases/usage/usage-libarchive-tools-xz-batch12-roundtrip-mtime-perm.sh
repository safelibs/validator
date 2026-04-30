#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-batch12-roundtrip-mtime-perm
# @title: bsdtar xz preserves mtime and perm
# @description: Round-trips a file through tar.xz with bsdtar -p and confirms mode bits and mtime survive compression and extraction.
# @timeout: 180
# @tags: usage, archive, xz
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in" "$tmpdir/out"
printf '#!/bin/sh\necho roundtrip\n' >"$tmpdir/in/script.sh"
chmod 750 "$tmpdir/in/script.sh"
# Pin a deterministic mtime so we can compare exactly.
touch -d '2021-06-15T12:34:56Z' "$tmpdir/in/script.sh"
mtime_in=$(stat -c %Y "$tmpdir/in/script.sh")
mode_in=$(stat -c %a "$tmpdir/in/script.sh")
sha_in=$(sha256sum "$tmpdir/in/script.sh" | awk '{print $1}')

bsdtar -cJf "$tmpdir/a.tar.xz" -C "$tmpdir/in" script.sh

# .xz magic
magic_hex=$(head -c 6 "$tmpdir/a.tar.xz" | od -An -tx1 | tr -d ' \n')
test "$magic_hex" = "fd377a585a00"

bsdtar -xpf "$tmpdir/a.tar.xz" -C "$tmpdir/out"

mtime_out=$(stat -c %Y "$tmpdir/out/script.sh")
mode_out=$(stat -c %a "$tmpdir/out/script.sh")
sha_out=$(sha256sum "$tmpdir/out/script.sh" | awk '{print $1}')

test "$mtime_in" = "$mtime_out"
test "$mode_in" = "$mode_out"
test "$sha_in" = "$sha_out"
