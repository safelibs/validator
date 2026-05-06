#!/usr/bin/env bash
# @testcase: usage-bzip2-r10-long-verbose-ratio-line
# @title: bzip2 --verbose long flag prints a ratio summary line on compress
# @description: Compresses a file with the --verbose long-form flag and verifies the per-file summary line on stderr contains the expected ratio, bits/byte, percent-saved and in/out byte fields.
# @timeout: 60
# @tags: usage, compression, long-flag, verbose
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# A repeating-pattern payload compresses well, giving a deterministic verbose line shape.
for i in $(seq 1 200); do
    printf 'verbose-ratio-line %s\n' "$i"
done >"$tmpdir/in.txt"

bzip2 --verbose "$tmpdir/in.txt" 2>"$tmpdir/err"

[[ -f "$tmpdir/in.txt.bz2" ]]
[[ ! -f "$tmpdir/in.txt" ]]

# The bzip2 verbose summary always contains these field names.
validator_assert_contains "$tmpdir/err" 'bits/byte'
validator_assert_contains "$tmpdir/err" '% saved'
validator_assert_contains "$tmpdir/err" ' in,'
validator_assert_contains "$tmpdir/err" ' out.'
