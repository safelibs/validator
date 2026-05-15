#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-r19-bsdtar-x-quiet-no-output-default
# @title: bsdtar -xf on a tar.zst archive emits no stdout/stderr noise on success
# @description: Extracts a tar.zst archive with bsdtar -xf without -v, captures stdout and stderr, and asserts both streams are empty in the success case to pin the libarchive default-quiet extraction behavior with zstd compression.
# @timeout: 60
# @tags: usage, archive, bsdtar, zstd, quiet, r19
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/src"
mkdir -p "$src"
printf 'r19 quiet payload\n' >"$src/payload.txt"
(cd "$src" && bsdtar --zstd -cf "$tmpdir/archive.tar.zst" payload.txt)

dest="$tmpdir/dest"
mkdir -p "$dest"
(cd "$dest" && bsdtar -xf "$tmpdir/archive.tar.zst") >"$tmpdir/out.log" 2>"$tmpdir/err.log"

[[ ! -s "$tmpdir/out.log" ]] || { echo "expected empty stdout"; cat "$tmpdir/out.log" >&2; exit 1; }
[[ ! -s "$tmpdir/err.log" ]] || { echo "expected empty stderr"; cat "$tmpdir/err.log" >&2; exit 1; }
validator_require_file "$dest/payload.txt"
