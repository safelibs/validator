#!/usr/bin/env bash
# @testcase: usage-bzip2-r12-stdin-multiple-streams-decode
# @title: bzip2 -dc on stdin decodes two concatenated streams in order
# @description: Concatenates two independently-compressed .bz2 streams and pipes the result into "bzip2 -dc" via stdin, asserting the decoded output equals the in-order concatenation of both source payloads.
# @timeout: 60
# @tags: usage, decompression, multistream, stdin
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'first-stream-bzip2-payload\n' >"$tmpdir/a.txt"
printf 'second-stream-bzip2-payload\n' >"$tmpdir/b.txt"

bzip2 -c "$tmpdir/a.txt" >"$tmpdir/a.bz2"
bzip2 -c "$tmpdir/b.txt" >"$tmpdir/b.bz2"
cat "$tmpdir/a.bz2" "$tmpdir/b.bz2" >"$tmpdir/both.bz2"

cat "$tmpdir/a.txt" "$tmpdir/b.txt" >"$tmpdir/expected.txt"
expected_sha=$(sha256sum "$tmpdir/expected.txt" | awk '{print $1}')

bzip2 -dc <"$tmpdir/both.bz2" >"$tmpdir/decoded.txt"
decoded_sha=$(sha256sum "$tmpdir/decoded.txt" | awk '{print $1}')

[[ "$expected_sha" == "$decoded_sha" ]]
