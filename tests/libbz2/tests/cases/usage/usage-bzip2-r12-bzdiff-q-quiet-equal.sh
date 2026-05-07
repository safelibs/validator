#!/usr/bin/env bash
# @testcase: usage-bzip2-r12-bzdiff-q-quiet-equal
# @title: bzdiff -q on two equal .bz2 archives is silent and exits zero
# @description: Compresses identical content into two .bz2 files and runs "bzdiff -q" on the pair, asserting exit zero and no output on stdout or stderr (quiet mode for matching files).
# @timeout: 60
# @tags: usage, bzdiff, quiet
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'identical-payload-line\nsecond-line\n' >"$tmpdir/a.txt"
cp "$tmpdir/a.txt" "$tmpdir/b.txt"
bzip2 "$tmpdir/a.txt" "$tmpdir/b.txt"

bzdiff -q "$tmpdir/a.txt.bz2" "$tmpdir/b.txt.bz2" >"$tmpdir/out.txt" 2>"$tmpdir/err.txt"

[[ ! -s "$tmpdir/out.txt" ]]
[[ ! -s "$tmpdir/err.txt" ]]
