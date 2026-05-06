#!/usr/bin/env bash
# @testcase: usage-bzip2-batch12-stdin-c-flag-stdout-pipeline
# @title: bzip2 -c reads stdin and writes compressed stream to stdout via temp files
# @description: Pipes input into bzip2 -c using temp files (no shell pipe to avoid SIGPIPE), then decompresses with bunzip2 -c and verifies the roundtripped bytes match.
# @timeout: 60
# @tags: usage, compression, stdin
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'pipeline input bytes\n' >"$tmpdir/in.txt"
bzip2 -c <"$tmpdir/in.txt" >"$tmpdir/mid.bz2"

# Verify magic bytes BZh
head -c 3 "$tmpdir/mid.bz2" | od -An -c | tr -d ' \n' | grep -q 'BZh'

bunzip2 -c <"$tmpdir/mid.bz2" >"$tmpdir/out.txt"
cmp "$tmpdir/in.txt" "$tmpdir/out.txt"
