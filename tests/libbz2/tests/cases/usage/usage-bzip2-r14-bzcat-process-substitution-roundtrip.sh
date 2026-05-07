#!/usr/bin/env bash
# @testcase: usage-bzip2-r14-bzcat-process-substitution-roundtrip
# @title: bzcat decodes a stream coming through bash process substitution
# @description: Pipes "bzip2 -c" output through bash process substitution into bzcat (bzcat <(bzip2 -c file)) and asserts the decoded stdout matches the source payload sha256, exercising bzcat reading from a process-substitution fifo file argument.
# @timeout: 60
# @tags: usage, bzcat, process-substitution
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 -c '
import sys
for i in range(120):
    sys.stdout.write("psub row %03d alpha beta\n" % i)
' >"$tmpdir/in.txt"
src_sha=$(sha256sum "$tmpdir/in.txt" | awk '{print $1}')

bzcat <(bzip2 -c "$tmpdir/in.txt") >"$tmpdir/out.txt"
out_sha=$(sha256sum "$tmpdir/out.txt" | awk '{print $1}')
test "$src_sha" = "$out_sha"
