#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-r9-include-pattern
# @title: bsdtar xz extract with --include pattern
# @description: Creates an xz tarball with mixed file extensions then extracts only entries matching --include '*.log' and confirms the other entries are not extracted.
# @timeout: 180
# @tags: usage, archive, compression
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in" "$tmpdir/out"
printf 'a\n' >"$tmpdir/in/a.log"
printf 'b\n' >"$tmpdir/in/b.txt"
printf 'c\n' >"$tmpdir/in/c.log"

( cd "$tmpdir/in" && bsdtar -cJf "$tmpdir/a.tar.xz" . )
bsdtar -xf "$tmpdir/a.tar.xz" -C "$tmpdir/out" --include '*.log'

[[ -f "$tmpdir/out/a.log" ]] || { printf 'missing a.log\n' >&2; exit 1; }
[[ -f "$tmpdir/out/c.log" ]] || { printf 'missing c.log\n' >&2; exit 1; }
[[ ! -f "$tmpdir/out/b.txt" ]] || { printf 'unexpected b.txt extracted\n' >&2; exit 1; }
