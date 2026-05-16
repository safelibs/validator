#!/usr/bin/env bash
# @testcase: usage-bzip2-r21-test-multistream-stdin
# @title: bzip2 -t accepts concatenated multi-stream input on stdin
# @description: Builds three independent bzip2 streams by compressing three different small payloads and concatenating them into one .bz2 blob, then pipes the blob into bzip2 -t (test-only) on stdin and asserts the exit code is 0 - locking in stdin-piped integrity checking across multi-stream archives.
# @timeout: 30
# @tags: usage, bzip2, test, multistream, stdin, r21
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'one\n' | bzip2 -c >"$tmpdir/a.bz2"
printf 'two\n' | bzip2 -c >"$tmpdir/b.bz2"
printf 'three\n' | bzip2 -c >"$tmpdir/c.bz2"
cat "$tmpdir/a.bz2" "$tmpdir/b.bz2" "$tmpdir/c.bz2" >"$tmpdir/all.bz2"

bzip2 -t <"$tmpdir/all.bz2"
