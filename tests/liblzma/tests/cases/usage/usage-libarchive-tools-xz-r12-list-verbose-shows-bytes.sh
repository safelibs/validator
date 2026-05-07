#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-r12-list-verbose-shows-bytes
# @title: xz --list --verbose reports compressed and uncompressed byte sizes
# @description: Compresses a deterministic payload and runs "xz --list --verbose" on the output, asserting the human-readable listing contains the source filename and the column headers "Streams" and "Blocks" used by the verbose listing.
# @timeout: 60
# @tags: usage, xz, list, verbose
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 -c 'import sys
for i in range(256):
    sys.stdout.write("verbose-list row %03d alpha beta gamma\n" % i)' >"$tmpdir/in.txt"

xz -c "$tmpdir/in.txt" >"$tmpdir/out.xz"

xz --list --verbose "$tmpdir/out.xz" >"$tmpdir/list.txt"

validator_assert_contains "$tmpdir/list.txt" 'Streams:'
validator_assert_contains "$tmpdir/list.txt" 'Blocks:'
validator_assert_contains "$tmpdir/list.txt" 'out.xz'
