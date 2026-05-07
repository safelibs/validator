#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-r14-xzcat-stdin-streaming
# @title: xzcat streams an .xz from stdin via shell pipeline
# @description: Pipes "xz -c" output directly into "xzcat" with no positional file argument, exercising xzcat's stdin path through a shell pipe rather than a redirected file, and asserts the recovered bytes match the source via sha256.
# @timeout: 60
# @tags: usage, xzcat, stdin, pipeline
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 -c '
import sys
for i in range(180):
    sys.stdout.write("xzcat-pipe row %03d alpha beta\n" % i)
' >"$tmpdir/in.txt"
src_sha=$(sha256sum "$tmpdir/in.txt" | awk '{print $1}')

xz -c "$tmpdir/in.txt" | xzcat >"$tmpdir/out.txt"
out_sha=$(sha256sum "$tmpdir/out.txt" | awk '{print $1}')
test "$src_sha" = "$out_sha"
