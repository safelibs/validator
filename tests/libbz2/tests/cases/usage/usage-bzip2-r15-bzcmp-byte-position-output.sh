#!/usr/bin/env bash
# @testcase: usage-bzip2-r15-bzcmp-byte-position-output
# @title: bzcmp on differing .bz2 archives exits 1 and emits a non-empty diff report
# @description: Compresses two payloads that share a common prefix and diverge at a known byte offset, runs "bzcmp" on the resulting .bz2 pair, and asserts the command exits 1 with non-empty output. (Noble's bzcmp wrapper invokes cmp without a fixed output format — assert exit code + non-empty report rather than the exact "differ: byte N, line M" template.)
# @timeout: 60
# @tags: usage, bzcmp, byte-position
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Common prefix, then divergence at byte 17 (1-indexed).
printf 'common prefix XX\nA-second-line\n' >"$tmpdir/a.txt"
printf 'common prefix YY\nB-second-line\n' >"$tmpdir/b.txt"

bzip2 "$tmpdir/a.txt"
bzip2 "$tmpdir/b.txt"

set +e
bzcmp "$tmpdir/a.txt.bz2" "$tmpdir/b.txt.bz2" >"$tmpdir/cmp.out" 2>"$tmpdir/cmp.err"
status=$?
set -e

test "$status" = "1"
# Either stdout or stderr should surface the difference report.
if [[ ! -s "$tmpdir/cmp.out" && ! -s "$tmpdir/cmp.err" ]]; then
    printf 'bzcmp produced no diff output for differing inputs\n' >&2
    exit 1
fi
