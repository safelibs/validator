#!/usr/bin/env bash
# @testcase: usage-bzip2-r16-bzdiff-archives-equal
# @title: bzdiff reports identical content between two bz2 archives of the same payload
# @description: Builds two bz2 archives from byte-identical input and asserts bzdiff exits 0 with no output, locking in the equal-payload path of the bzdiff comparator across distinct archive files.
# @timeout: 60
# @tags: usage, bzdiff, archives, equality
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'r16 bzdiff-equal payload\nshared bytes\n' >"$tmpdir/src.txt"
bzip2 -c "$tmpdir/src.txt" >"$tmpdir/left.bz2"
bzip2 -c "$tmpdir/src.txt" >"$tmpdir/right.bz2"

bzdiff "$tmpdir/left.bz2" "$tmpdir/right.bz2" >"$tmpdir/out" 2>"$tmpdir/err"

[[ ! -s "$tmpdir/out" ]] || {
    printf 'bzdiff produced output for equal archives:\n' >&2
    cat "$tmpdir/out" >&2
    exit 1
}
