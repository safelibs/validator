#!/usr/bin/env bash
# @testcase: usage-bzip2-r20-bzdiff-three-archives-pairwise-equal
# @title: bzdiff returns rc 0 for two archives with identical payloads compressed at different levels
# @description: Writes the same source payload, compresses it twice with bzip2 at -3 and at -7 into distinct archive files, then runs bzdiff between the two archives and asserts rc 0 since the decompressed payloads are identical, exercising bzdiff's content-equality semantics across mixed compression levels distinct from prior same-level or three-way tests.
# @timeout: 30
# @tags: usage, bzdiff, mixed-level, r20
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'r20 bzdiff payload\nsecond line of body\nthird line\n' >"$tmpdir/src.txt"

bzip2 -3 -c "$tmpdir/src.txt" >"$tmpdir/a.bz2"
bzip2 -7 -c "$tmpdir/src.txt" >"$tmpdir/b.bz2"

# Both archives must decompress to the same payload but be byte-distinct as files
if cmp -s "$tmpdir/a.bz2" "$tmpdir/b.bz2"; then
    printf 'archives unexpectedly equal\n' >&2
    exit 1
fi

bzdiff "$tmpdir/a.bz2" "$tmpdir/b.bz2"
