#!/usr/bin/env bash
# @testcase: usage-bzip2-r15-bzcmp-byte-position-output
# @title: bzcmp on differing .bz2 archives reports a byte-position diff line
# @description: Compresses two payloads that share a common prefix and diverge at a known byte offset, runs "bzcmp" on the resulting .bz2 pair (which decompresses both and forwards to cmp), and asserts the command exits 1 with a stdout line of the form "<filea> <fileb> differ: byte <N>, line <M>", confirming bzcmp surfaces cmp's default byte/line position output.
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
# cmp's default output: "<a> <b> differ: byte N, line M"
grep -Eq 'differ: byte [0-9]+, line [0-9]+' "$tmpdir/cmp.out"
