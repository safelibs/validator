#!/usr/bin/env bash
# @testcase: usage-bzip2-r10-tbz-suffix-decompress
# @title: bzip2 -d on a .tbz file strips the suffix to .tar
# @description: Renames a valid bz2-compressed file to use the .tbz suffix and verifies bzip2 -d strips the suffix to produce a .tar named output, matching the documented suffix table.
# @timeout: 60
# @tags: usage, decompression, suffix
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'tbz suffix payload\n' >"$tmpdir/payload"
bzip2 "$tmpdir/payload"
mv "$tmpdir/payload.bz2" "$tmpdir/archive.tbz"

bzip2 -d "$tmpdir/archive.tbz"

[[ -f "$tmpdir/archive.tar" ]]
[[ ! -f "$tmpdir/archive.tbz" ]]
grep -Fq 'tbz suffix payload' "$tmpdir/archive.tar"
