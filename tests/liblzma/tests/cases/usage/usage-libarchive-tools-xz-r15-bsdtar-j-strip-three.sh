#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-r15-bsdtar-j-strip-three
# @title: bsdtar -xJf with --strip-components=3 extracts only the deepest leaf into the output root
# @description: Builds a tar.xz containing a single deeply-nested member at "root/dir/sub/leaf.txt" via "bsdtar -cJf", lists the archive to confirm the prefix path, then extracts with "--strip-components=3" against a fresh output directory and asserts only "leaf.txt" appears at the output root with the original sha256 — exercising a triple strip distinct from the existing single-strip and double-strip cases.
# @timeout: 90
# @tags: usage, bsdtar, xz, strip-components
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in/root/dir/sub" "$tmpdir/out"
printf 'r15 strip-three deep payload alpha\n' >"$tmpdir/in/root/dir/sub/leaf.txt"
src_sha=$(sha256sum "$tmpdir/in/root/dir/sub/leaf.txt" | awk '{print $1}')

bsdtar -cJf "$tmpdir/a.tar.xz" -C "$tmpdir/in" 'root/dir/sub/leaf.txt'

# .xz magic.
magic_hex=$(head -c 6 "$tmpdir/a.tar.xz" | od -An -tx1 | tr -d ' \n')
test "$magic_hex" = "fd377a585a00"

bsdtar -tJf "$tmpdir/a.tar.xz" >"$tmpdir/list.txt"
grep -Fxq 'root/dir/sub/leaf.txt' "$tmpdir/list.txt"

bsdtar --strip-components=3 -xJf "$tmpdir/a.tar.xz" -C "$tmpdir/out"

# After triple-strip, leaf.txt is at the output root and no parent-dir wrappers.
test -f "$tmpdir/out/leaf.txt"
test ! -e "$tmpdir/out/root"
test ! -e "$tmpdir/out/dir"
test ! -e "$tmpdir/out/sub"

out_sha=$(sha256sum "$tmpdir/out/leaf.txt" | awk '{print $1}')
test "$src_sha" = "$out_sha"
