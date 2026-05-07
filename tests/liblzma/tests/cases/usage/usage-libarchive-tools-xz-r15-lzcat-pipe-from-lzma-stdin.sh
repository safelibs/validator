#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-r15-lzcat-pipe-from-lzma-stdin
# @title: lzcat decodes a legacy .lzma stream piped from lzma -c on stdin
# @description: Pipes "lzma -c" output directly into "lzcat" (no intermediate file, no positional argument), exercising lzcat's stdin path against a legacy .lzma stream. Asserts the recovered bytes match the source sha256 — distinct from the r14 lzcat-from-lzma-file case which uses a file argument.
# @timeout: 60
# @tags: usage, lzcat, lzma, stdin, pipeline
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 -c '
import sys
for i in range(140):
    sys.stdout.write("r15 lzcat-pipe row %03d alpha\n" % i)
' >"$tmpdir/in.txt"
src_sha=$(sha256sum "$tmpdir/in.txt" | awk '{print $1}')

lzma -c "$tmpdir/in.txt" | lzcat >"$tmpdir/out.txt"

out_sha=$(sha256sum "$tmpdir/out.txt" | awk '{print $1}')
test "$src_sha" = "$out_sha"
