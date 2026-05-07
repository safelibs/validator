#!/usr/bin/env bash
# @testcase: usage-bzip2-r13-bzcat-stdin-concatenated-streams
# @title: bzcat reads concatenated bz2 streams from stdin
# @description: Concatenates two distinct .bz2 streams and pipes the result into bzcat via stdin, then asserts the decoded stdout equals the in-order concatenation of both source payloads.
# @timeout: 60
# @tags: usage, bzcat, stdin, multistream
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'first concatenated payload alpha\n' >"$tmpdir/a.txt"
printf 'second concatenated payload beta\n' >"$tmpdir/b.txt"

bzip2 -c "$tmpdir/a.txt" >"$tmpdir/concat.bz2"
bzip2 -c "$tmpdir/b.txt" >>"$tmpdir/concat.bz2"

cat "$tmpdir/a.txt" "$tmpdir/b.txt" >"$tmpdir/expected.txt"
expected_sha=$(sha256sum "$tmpdir/expected.txt" | awk '{print $1}')

bzcat <"$tmpdir/concat.bz2" >"$tmpdir/decoded.txt"
out_sha=$(sha256sum "$tmpdir/decoded.txt" | awk '{print $1}')

test "$expected_sha" = "$out_sha"
