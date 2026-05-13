#!/usr/bin/env bash
# @testcase: usage-bzip2-r16-bzcat-three-files-concat-order
# @title: bzcat preserves argument order when decoding three separate bz2 files
# @description: Compresses three distinct payloads into separate .bz2 files and asserts bzcat decoded in the supplied argument order produces line-for-line the concatenation of the original payloads in that order — exercising bzcat's positional argument semantics with a stable line-based assertion.
# @timeout: 60
# @tags: usage, bzcat, multi-file, order
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'r16-first\n' >"$tmpdir/a.txt"
printf 'r16-second\n' >"$tmpdir/b.txt"
printf 'r16-third\n' >"$tmpdir/c.txt"
bzip2 -c "$tmpdir/a.txt" >"$tmpdir/a.bz2"
bzip2 -c "$tmpdir/b.txt" >"$tmpdir/b.bz2"
bzip2 -c "$tmpdir/c.txt" >"$tmpdir/c.bz2"

bzcat "$tmpdir/c.bz2" "$tmpdir/a.bz2" "$tmpdir/b.bz2" >"$tmpdir/order.txt"

# Order in argument list: c then a then b
mapfile -t lines <"$tmpdir/order.txt"
[[ "${lines[0]}" == "r16-third" ]]
[[ "${lines[1]}" == "r16-first" ]]
[[ "${lines[2]}" == "r16-second" ]]
