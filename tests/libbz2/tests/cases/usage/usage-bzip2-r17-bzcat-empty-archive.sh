#!/usr/bin/env bash
# @testcase: usage-bzip2-r17-bzcat-empty-archive
# @title: bzcat on a bz2 of an empty file emits zero bytes
# @description: Compresses an empty file with bzip2 to produce a non-empty archive, then runs bzcat against it and asserts the stdout contains exactly zero bytes — locking in the empty-payload contract distinct from a truncated archive.
# @timeout: 30
# @tags: usage, bzcat, empty
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

: >"$tmpdir/empty.txt"
bzip2 -c "$tmpdir/empty.txt" >"$tmpdir/empty.bz2"

archive_bytes=$(wc -c <"$tmpdir/empty.bz2")
[[ "$archive_bytes" -gt 0 ]] || {
    printf 'expected non-empty bz2 archive for empty input, got %s\n' "$archive_bytes" >&2
    exit 1
}

bzcat "$tmpdir/empty.bz2" >"$tmpdir/out"
out_bytes=$(wc -c <"$tmpdir/out")
[[ "$out_bytes" -eq 0 ]] || {
    printf 'expected zero output bytes, got %s\n' "$out_bytes" >&2
    exit 1
}
