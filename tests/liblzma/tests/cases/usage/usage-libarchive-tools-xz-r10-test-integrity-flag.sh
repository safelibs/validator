#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-r10-test-integrity-flag
# @title: xz -t verifies xz file integrity
# @description: Encodes a tarball with xz, runs xz -t to verify the integrity check passes for the well-formed stream, then truncates the file and asserts xz -t fails on the corrupted stream.
# @timeout: 180
# @tags: usage, xz, integrity, test
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in"
python3 -c 'import sys
for i in range(1024):
    sys.stdout.write("integrity row %05d theta iota kappa lambda mu\n" % i)' \
  >"$tmpdir/in/payload.txt"

bsdtar -cJf "$tmpdir/a.tar.xz" -C "$tmpdir/in" payload.txt

xz -t "$tmpdir/a.tar.xz"

orig_size=$(wc -c <"$tmpdir/a.tar.xz")
truncated_size=$((orig_size - 32))
test "$truncated_size" -gt 32
dd if="$tmpdir/a.tar.xz" of="$tmpdir/truncated.xz" bs=1 count="$truncated_size" status=none

if xz -t "$tmpdir/truncated.xz" 2>"$tmpdir/err"; then
    printf 'expected xz -t to fail on truncated stream\n' >&2
    exit 1
fi
