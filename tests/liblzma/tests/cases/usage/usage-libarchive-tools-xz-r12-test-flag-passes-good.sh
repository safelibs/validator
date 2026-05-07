#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-r12-test-flag-passes-good
# @title: xz -t integrity check exits zero on a valid stream
# @description: Compresses a payload, runs "xz -t" on the .xz file, and asserts exit zero with no stdout output (integrity check passes for unmodified stream).
# @timeout: 60
# @tags: usage, xz, integrity, test
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 -c 'import sys
for i in range(150):
    sys.stdout.write("xz-test row %03d alpha beta\n" % i)' >"$tmpdir/in.txt"

xz "$tmpdir/in.txt"
test -f "$tmpdir/in.txt.xz"

xz -t "$tmpdir/in.txt.xz" >"$tmpdir/out.txt" 2>"$tmpdir/err.txt"
test ! -s "$tmpdir/out.txt"
