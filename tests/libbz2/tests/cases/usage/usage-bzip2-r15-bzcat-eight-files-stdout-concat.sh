#!/usr/bin/env bash
# @testcase: usage-bzip2-r15-bzcat-eight-files-stdout-concat
# @title: bzcat decodes eight .bz2 files in one call concatenated to stdout
# @description: Compresses eight distinct payloads to .bz2 files, runs "bzcat f1.bz2 ... f8.bz2" with all eight as positional arguments, and asserts the stdout sha256 equals the byte-wise concatenation of the eight original payloads — exercising bzcat's many-file argument path beyond the existing two/three-file cases.
# @timeout: 60
# @tags: usage, bzcat, multi-file
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

for i in 1 2 3 4 5 6 7 8; do
    printf 'r15 bzcat-eight payload chunk %d alpha\n' "$i" >"$tmpdir/p${i}.txt"
    bzip2 -c "$tmpdir/p${i}.txt" >"$tmpdir/p${i}.bz2"
done

cat "$tmpdir/p1.txt" "$tmpdir/p2.txt" "$tmpdir/p3.txt" "$tmpdir/p4.txt" \
    "$tmpdir/p5.txt" "$tmpdir/p6.txt" "$tmpdir/p7.txt" "$tmpdir/p8.txt" \
    >"$tmpdir/expected.txt"
expected_sha=$(sha256sum "$tmpdir/expected.txt" | awk '{print $1}')

bzcat "$tmpdir/p1.bz2" "$tmpdir/p2.bz2" "$tmpdir/p3.bz2" "$tmpdir/p4.bz2" \
      "$tmpdir/p5.bz2" "$tmpdir/p6.bz2" "$tmpdir/p7.bz2" "$tmpdir/p8.bz2" \
      >"$tmpdir/decoded.txt"
out_sha=$(sha256sum "$tmpdir/decoded.txt" | awk '{print $1}')
test "$expected_sha" = "$out_sha"
