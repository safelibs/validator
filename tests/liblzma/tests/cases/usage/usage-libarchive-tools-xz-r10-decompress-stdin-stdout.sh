#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-r10-decompress-stdin-stdout
# @title: xz -d streams stdin to stdout
# @description: Pipes a .xz stream into xz -d on stdin and asserts the decoded stdout exactly matches the original payload, exercising liblzma's stream decoder.
# @timeout: 120
# @tags: usage, xz, stdin, stdout
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 -c 'import sys
for i in range(512):
    sys.stdout.write("stdin row %04d kappa lambda mu nu xi omicron\n" % i)' \
  >"$tmpdir/payload.txt"
src_sha=$(sha256sum "$tmpdir/payload.txt" | awk '{print $1}')

xz -z -c "$tmpdir/payload.txt" >"$tmpdir/payload.xz"

xz -d <"$tmpdir/payload.xz" >"$tmpdir/decoded.txt"
out_sha=$(sha256sum "$tmpdir/decoded.txt" | awk '{print $1}')
test "$src_sha" = "$out_sha"

cmp "$tmpdir/payload.txt" "$tmpdir/decoded.txt"
