#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-r9-bsdtar-symlink-restore
# @title: bsdtar zstd preserves a symlink across roundtrip
# @description: Archives a directory containing a symlink with bsdtar --zstd, extracts it elsewhere, and asserts the extracted symlink still points to its original target.
# @timeout: 180
# @tags: usage, archive, zstd
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in" "$tmpdir/out"
printf 'real payload\n' >"$tmpdir/in/target.txt"
ln -s target.txt "$tmpdir/in/link.txt"

bsdtar --zstd -cf "$tmpdir/a.tar.zst" -C "$tmpdir/in" .
bsdtar -xf "$tmpdir/a.tar.zst" -C "$tmpdir/out"

[[ -L "$tmpdir/out/link.txt" ]] || { echo "not a symlink" >&2; exit 1; }
target=$(readlink "$tmpdir/out/link.txt")
[[ "$target" == "target.txt" ]] || { echo "target=$target" >&2; exit 1; }
[[ "$(cat "$tmpdir/out/link.txt")" == "real payload" ]]
