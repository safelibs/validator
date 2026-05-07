#!/usr/bin/env bash
# @testcase: usage-bzip2-r13-keep-stdout-leaves-input
# @title: bzip2 -kc emits stdout and leaves the input file untouched
# @description: Runs "bzip2 -kc input" to write the compressed stream to stdout while keeping the input, asserts no input.bz2 sibling is created, the source file is byte-identical to its pre-run sha256, and the stdout stream is a valid bz2 file by header magic and "bzip2 -t".
# @timeout: 60
# @tags: usage, bzip2, keep, stdout
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'keep-stdout payload\nrow two\nrow three\n' >"$tmpdir/in.txt"
src_sha=$(sha256sum "$tmpdir/in.txt" | awk '{print $1}')

bzip2 -kc "$tmpdir/in.txt" >"$tmpdir/out.bz2"

# Source must be untouched.
post_sha=$(sha256sum "$tmpdir/in.txt" | awk '{print $1}')
test "$src_sha" = "$post_sha"
[[ ! -e "$tmpdir/in.txt.bz2" ]]

# Output must be a real bz2 stream.
magic=$(head -c 3 "$tmpdir/out.bz2")
[[ "$magic" = "BZh" ]]
bzip2 -t "$tmpdir/out.bz2"
