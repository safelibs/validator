#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-r9-bsdtar-from-stdin-pipe
# @title: bsdtar xz reads tarball via stdin
# @description: Pipes an xz-compressed tarball to bsdtar -tf - and verifies the listing contains the original entry name.
# @timeout: 180
# @tags: usage, archive, compression
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in"
printf 'stdin pipe content\n' >"$tmpdir/in/streamed.txt"
( cd "$tmpdir/in" && bsdtar -cJf "$tmpdir/a.tar.xz" streamed.txt )

bsdtar -tf - <"$tmpdir/a.tar.xz" >"$tmpdir/list.txt"
grep -q '^streamed.txt$' "$tmpdir/list.txt" || { printf 'missing entry\n' >&2; cat "$tmpdir/list.txt" >&2; exit 1; }
