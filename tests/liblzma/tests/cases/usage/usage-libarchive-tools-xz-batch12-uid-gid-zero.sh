#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-batch12-uid-gid-zero
# @title: bsdtar xz uid gid zero override
# @description: Creates an xz tarball with --uid 0 --gid 0 overrides and confirms bsdtar -tv reports the rewritten owner identifiers.
# @timeout: 180
# @tags: usage, archive, xz
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in" "$tmpdir/out"
printf 'owner override payload\n' >"$tmpdir/in/payload.txt"

bsdtar --uid 0 --gid 0 --uname root --gname root \
  -cJf "$tmpdir/a.tar.xz" -C "$tmpdir/in" payload.txt

# .xz magic
magic_hex=$(head -c 6 "$tmpdir/a.tar.xz" | od -An -tx1 | tr -d ' \n')
test "$magic_hex" = "fd377a585a00"

# Verbose listing must show the overridden owner
bsdtar -tvf "$tmpdir/a.tar.xz" >"$tmpdir/list.txt"
grep -Eq '(^| )root[/ ]+root( |$)' "$tmpdir/list.txt"

# Round-trip still produces byte-identical content
bsdtar -xf "$tmpdir/a.tar.xz" -C "$tmpdir/out"
cmp "$tmpdir/in/payload.txt" "$tmpdir/out/payload.txt"
