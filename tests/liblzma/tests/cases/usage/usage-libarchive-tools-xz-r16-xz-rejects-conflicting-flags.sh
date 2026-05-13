#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-r16-xz-rejects-conflicting-flags
# @title: xz -z -d combined on the same invocation exits non-zero with an error message
# @description: Runs xz -z -d (asking to both compress AND decompress) and asserts the process exits with a non-zero status AND emits a diagnostic to stderr, pinning xz's argv conflict detection on Ubuntu 24.04.
# @timeout: 60
# @tags: usage, xz, error, argv
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'payload\n' >"$tmpdir/in.txt"
status=0
xz -z -d -c "$tmpdir/in.txt" >"$tmpdir/out.bin" 2>"$tmpdir/err.txt" || status=$?
test "$status" -ne 0
test -s "$tmpdir/err.txt"
