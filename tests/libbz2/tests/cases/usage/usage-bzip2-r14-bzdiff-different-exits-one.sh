#!/usr/bin/env bash
# @testcase: usage-bzip2-r14-bzdiff-different-exits-one
# @title: bzdiff on differing .bz2 archives exits 1 and emits diff output
# @description: Compresses two distinct payloads, runs bzdiff on the resulting .bz2 pair, and asserts the command exits 1 (the diff exit code for differences) with non-empty stdout, complementing the equal-files exit-zero r13 case.
# @timeout: 60
# @tags: usage, bzdiff, exit-code
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'first payload alpha\n' >"$tmpdir/a.txt"
printf 'second payload BETA\n' >"$tmpdir/b.txt"

bzip2 "$tmpdir/a.txt"
bzip2 "$tmpdir/b.txt"

set +e
bzdiff "$tmpdir/a.txt.bz2" "$tmpdir/b.txt.bz2" >"$tmpdir/diff.out" 2>"$tmpdir/diff.err"
status=$?
set -e

test "$status" = "1"
[[ -s "$tmpdir/diff.out" ]]
