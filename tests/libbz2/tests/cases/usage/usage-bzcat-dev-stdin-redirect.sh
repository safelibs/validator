#!/usr/bin/env bash
# @testcase: usage-bzcat-dev-stdin-redirect
# @title: bzcat /dev/stdin redirected from .bz2
# @description: Feeds a bzip2-compressed file into bzcat by passing /dev/stdin as an explicit argument while redirecting fd 0 from the .bz2 file, and verifies the output matches the original bytes.
# @timeout: 180
# @tags: usage, bzcat, stdin
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bzcat-dev-stdin-redirect"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 -c "import sys
for i in range(48):
    sys.stdout.write(f'bzcat /dev/stdin payload {i}\n')" >"$tmpdir/in.txt"

bzip2 -c "$tmpdir/in.txt" >"$tmpdir/in.bz2"

# Explicitly hand bzcat /dev/stdin while redirecting from the compressed file.
bzcat /dev/stdin <"$tmpdir/in.bz2" >"$tmpdir/out.txt"
cmp "$tmpdir/in.txt" "$tmpdir/out.txt"
