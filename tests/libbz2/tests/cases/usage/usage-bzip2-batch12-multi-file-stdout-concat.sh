#!/usr/bin/env bash
# @testcase: usage-bzip2-batch12-multi-file-stdout-concat
# @title: bzip2 -dc concatenates multiple bz2 files in argument order
# @description: Compresses three text files separately, then runs bzip2 -dc with all three as arguments and verifies the concatenated output equals the original three files concatenated.
# @timeout: 60
# @tags: usage, compression, multi
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'one\n' >"$tmpdir/a.txt"
printf 'two\n' >"$tmpdir/b.txt"
printf 'three\n' >"$tmpdir/c.txt"

bzip2 -k "$tmpdir/a.txt" "$tmpdir/b.txt" "$tmpdir/c.txt"

cat "$tmpdir/a.txt" "$tmpdir/b.txt" "$tmpdir/c.txt" >"$tmpdir/expected.txt"
bzip2 -dc "$tmpdir/a.txt.bz2" "$tmpdir/b.txt.bz2" "$tmpdir/c.txt.bz2" >"$tmpdir/got.txt"
cmp "$tmpdir/expected.txt" "$tmpdir/got.txt"
