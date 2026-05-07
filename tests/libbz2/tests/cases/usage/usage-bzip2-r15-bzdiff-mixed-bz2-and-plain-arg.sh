#!/usr/bin/env bash
# @testcase: usage-bzip2-r15-bzdiff-mixed-bz2-and-plain-arg
# @title: bzdiff compares a .bz2 archive against an uncompressed file directly
# @description: Compresses one payload to .bz2, leaves a second payload uncompressed on disk, runs "bzdiff a.txt.bz2 b.txt" with one compressed and one plain argument, and asserts the command exits 1 with a non-empty diff because the contents differ — confirming bzdiff transparently decodes only the .bz2 side of a mixed-pair invocation.
# @timeout: 60
# @tags: usage, bzdiff, mixed
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'r15 mixed-arg payload alpha\nbody line two\n' >"$tmpdir/a.txt"
printf 'r15 mixed-arg payload BETA\nbody line two\n' >"$tmpdir/b.txt"

bzip2 "$tmpdir/a.txt"
[[ -f "$tmpdir/a.txt.bz2" ]]
[[ -f "$tmpdir/b.txt" ]]

set +e
bzdiff "$tmpdir/a.txt.bz2" "$tmpdir/b.txt" >"$tmpdir/diff.out" 2>"$tmpdir/diff.err"
status=$?
set -e

test "$status" = "1"
[[ -s "$tmpdir/diff.out" ]]
