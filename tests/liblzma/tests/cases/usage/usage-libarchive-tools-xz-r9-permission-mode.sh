#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-r9-permission-mode
# @title: bsdtar xz preserves file permission mode
# @description: Creates an xz tarball containing a file with mode 0750, extracts it with --preserve-permissions, and verifies the extracted file has mode 0750.
# @timeout: 180
# @tags: usage, archive, compression
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in" "$tmpdir/out"
printf 'mode payload\n' >"$tmpdir/in/f.txt"
chmod 0750 "$tmpdir/in/f.txt"
( cd "$tmpdir/in" && bsdtar -cJf "$tmpdir/a.tar.xz" f.txt )
bsdtar -xpf "$tmpdir/a.tar.xz" -C "$tmpdir/out"
mode=$(stat -c '%a' "$tmpdir/out/f.txt")
[[ "$mode" == "750" ]] || { printf 'expected 750, got %s\n' "$mode" >&2; exit 1; }
