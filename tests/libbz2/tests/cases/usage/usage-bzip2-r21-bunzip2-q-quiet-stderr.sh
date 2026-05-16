#!/usr/bin/env bash
# @testcase: usage-bzip2-r21-bunzip2-q-quiet-stderr
# @title: bunzip2 -q produces no stderr output for a clean archive
# @description: Compresses a small payload, decompresses with bunzip2 -q -k to stdout, and asserts the captured stderr stream is empty - locking in bunzip2's -q (quiet) behavior on the bunzip2 wrapper (existing tests cover bzip2 -q but not bunzip2 -q on stderr emptiness).
# @timeout: 30
# @tags: usage, bunzip2, quiet, stderr, r21
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'quiet-test-payload\n' >"$tmpdir/in.txt"
bzip2 "$tmpdir/in.txt"

bunzip2 -q -k -c "$tmpdir/in.txt.bz2" >"$tmpdir/out.txt" 2>"$tmpdir/err"

[[ -s "$tmpdir/err" ]] && {
    printf 'expected empty stderr, got:\n' >&2
    cat "$tmpdir/err" >&2
    exit 1
}
validator_assert_contains "$tmpdir/out.txt" 'quiet-test-payload'
