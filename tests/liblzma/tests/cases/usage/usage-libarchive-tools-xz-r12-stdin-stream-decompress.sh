#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-r12-stdin-stream-decompress
# @title: xz -d reads xz stream from stdin redirection
# @description: Compresses a payload to a .xz file, then runs "xz -d -c" with stdin redirected from the .xz file (no positional argument) and asserts the stdout matches the source bytes via sha256.
# @timeout: 60
# @tags: usage, xz, stdin
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 -c 'import sys
for i in range(200):
    sys.stdout.write("xz stdin row %03d alpha\n" % i)' >"$tmpdir/in.txt"
src_sha=$(sha256sum "$tmpdir/in.txt" | awk '{print $1}')

xz -c "$tmpdir/in.txt" >"$tmpdir/out.xz"

xz -d -c <"$tmpdir/out.xz" >"$tmpdir/decoded.txt"
out_sha=$(sha256sum "$tmpdir/decoded.txt" | awk '{print $1}')
test "$src_sha" = "$out_sha"
