#!/usr/bin/env bash
# @testcase: usage-bzip2-r12-bzcat-stdin-redirect
# @title: bzcat reads .bz2 stream from stdin via shell redirection
# @description: Compresses a payload, then runs bzcat with no arguments and stdin redirected from the .bz2 file (< file), and verifies the decoded stdout matches the original payload byte-for-byte.
# @timeout: 60
# @tags: usage, bzcat, stdin
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

for i in $(seq 1 150); do
    printf 'bzcat-stdin row %03d\n' "$i"
done >"$tmpdir/in.txt"
orig_sha=$(sha256sum "$tmpdir/in.txt" | awk '{print $1}')

bzip2 --keep "$tmpdir/in.txt"
[[ -f "$tmpdir/in.txt.bz2" ]]

bzcat <"$tmpdir/in.txt.bz2" >"$tmpdir/out.txt"

out_sha=$(sha256sum "$tmpdir/out.txt" | awk '{print $1}')
[[ "$orig_sha" == "$out_sha" ]]
