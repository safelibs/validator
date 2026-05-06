#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-r9-bsdtar-include-glob
# @title: bsdtar zstd extract include glob filter
# @description: Builds a zstd archive with mixed file extensions and extracts only *.log entries via --include='*.log', verifying matching files are present and other files are absent.
# @timeout: 180
# @tags: usage, archive, zstd
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in" "$tmpdir/out"
printf 'log a\n' >"$tmpdir/in/a.log"
printf 'log b\n' >"$tmpdir/in/b.log"
printf 'data\n' >"$tmpdir/in/c.dat"

bsdtar --zstd -cf "$tmpdir/a.tar.zst" -C "$tmpdir/in" .
bsdtar -xf "$tmpdir/a.tar.zst" -C "$tmpdir/out" --include='*.log'

[[ -f "$tmpdir/out/a.log" ]] || { echo "missing a.log" >&2; exit 1; }
[[ -f "$tmpdir/out/b.log" ]] || { echo "missing b.log" >&2; exit 1; }
[[ ! -f "$tmpdir/out/c.dat" ]] || { echo "c.dat should be filtered out" >&2; exit 1; }
