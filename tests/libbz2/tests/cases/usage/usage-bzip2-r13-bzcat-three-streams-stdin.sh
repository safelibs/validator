#!/usr/bin/env bash
# @testcase: usage-bzip2-r13-bzcat-three-streams-stdin
# @title: bzcat reads three concatenated bz2 streams from stdin
# @description: Builds a single concatenated .bz2 file from three independent compress invocations and decodes it through "bzcat" stdin redirection, asserting the decoded bytes are the in-order concatenation of all three sources.
# @timeout: 60
# @tags: usage, bzcat, multistream
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'three-stream-1\n' >"$tmpdir/p1.txt"
printf 'three-stream-2 longer\n' >"$tmpdir/p2.txt"
printf 'three-stream-3 final piece\n' >"$tmpdir/p3.txt"

bzip2 -c "$tmpdir/p1.txt" >"$tmpdir/concat.bz2"
bzip2 -c "$tmpdir/p2.txt" >>"$tmpdir/concat.bz2"
bzip2 -c "$tmpdir/p3.txt" >>"$tmpdir/concat.bz2"

cat "$tmpdir/p1.txt" "$tmpdir/p2.txt" "$tmpdir/p3.txt" >"$tmpdir/expected.txt"
expected_sha=$(sha256sum "$tmpdir/expected.txt" | awk '{print $1}')

bzcat <"$tmpdir/concat.bz2" >"$tmpdir/decoded.txt"
out_sha=$(sha256sum "$tmpdir/decoded.txt" | awk '{print $1}')
test "$expected_sha" = "$out_sha"
