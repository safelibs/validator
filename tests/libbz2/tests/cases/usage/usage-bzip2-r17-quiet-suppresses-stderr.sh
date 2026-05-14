#!/usr/bin/env bash
# @testcase: usage-bzip2-r17-quiet-suppresses-stderr
# @title: bzip2 --quiet writes no stderr noise while -v emits progress text
# @description: Compresses the same payload twice — once with --quiet and once with -v — and asserts the --quiet invocation produces an empty stderr file while the -v invocation produces a non-empty stderr, locking in the verbosity contrast between the two flags.
# @timeout: 60
# @tags: usage, bzip2, quiet, verbose
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'r17 quiet flag test\nrow alpha\nrow bravo\nrow charlie\n' >"$tmpdir/payload.txt"
cp "$tmpdir/payload.txt" "$tmpdir/payload-q.txt"
cp "$tmpdir/payload.txt" "$tmpdir/payload-v.txt"

bzip2 --quiet "$tmpdir/payload-q.txt" 2>"$tmpdir/quiet.err"
bzip2 -v "$tmpdir/payload-v.txt" 2>"$tmpdir/verbose.err"

quiet_bytes=$(wc -c <"$tmpdir/quiet.err")
verbose_bytes=$(wc -c <"$tmpdir/verbose.err")
[[ "$quiet_bytes" -eq 0 ]] || {
    printf 'expected empty --quiet stderr, got %s bytes\n' "$quiet_bytes" >&2
    cat "$tmpdir/quiet.err" >&2
    exit 1
}
[[ "$verbose_bytes" -gt 0 ]] || {
    printf 'expected -v to emit stderr progress, got nothing\n' >&2
    exit 1
}
