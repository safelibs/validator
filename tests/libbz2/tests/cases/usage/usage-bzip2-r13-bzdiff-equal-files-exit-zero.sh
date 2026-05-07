#!/usr/bin/env bash
# @testcase: usage-bzip2-r13-bzdiff-equal-files-exit-zero
# @title: bzdiff on two byte-identical bz2 files exits zero with no diff output
# @description: Compresses the same payload twice into separate .bz2 files (decompressed contents are identical), runs bzdiff on the pair, and asserts exit zero plus an empty stdout (no diff output).
# @timeout: 60
# @tags: usage, bzdiff
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'identical payload\nshared line\n' >"$tmpdir/a.txt"
cp "$tmpdir/a.txt" "$tmpdir/b.txt"

bzip2 "$tmpdir/a.txt"
bzip2 "$tmpdir/b.txt"

bzdiff "$tmpdir/a.txt.bz2" "$tmpdir/b.txt.bz2" >"$tmpdir/diff.out"
[[ ! -s "$tmpdir/diff.out" ]]
