#!/usr/bin/env bash
# @testcase: usage-bzip2-r21-bzdiff-q-equal-archives-rc-zero
# @title: bzdiff -q on two archives with identical contents exits 0 with no output
# @description: Compresses identical content into two distinct archives, runs bzdiff -q on them, and asserts the exit code is 0 with no stdout/stderr output - locking in the -q quiet flag's silent-success behavior distinct from the existing bzdiff-q-flag test which only checks rc on differing files.
# @timeout: 30
# @tags: usage, bzdiff, quiet, r21
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'identical-r21\n' >"$tmpdir/a.txt"
printf 'identical-r21\n' >"$tmpdir/b.txt"
bzip2 "$tmpdir/a.txt"
bzip2 "$tmpdir/b.txt"

bzdiff -q "$tmpdir/a.txt.bz2" "$tmpdir/b.txt.bz2" >"$tmpdir/out" 2>"$tmpdir/err"
if [[ -s "$tmpdir/out" ]]; then
    echo 'expected empty stdout' >&2
    cat "$tmpdir/out" >&2
    exit 1
fi
if [[ -s "$tmpdir/err" ]]; then
    echo 'expected empty stderr' >&2
    cat "$tmpdir/err" >&2
    exit 1
fi
