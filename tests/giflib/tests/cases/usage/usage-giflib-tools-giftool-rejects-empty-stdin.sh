#!/usr/bin/env bash
# @testcase: usage-giflib-tools-giftool-rejects-empty-stdin
# @title: giftool exits non-zero with a GIF-LIB read error on empty stdin
# @description: Invokes giftool -d 0 with /dev/null as stdin, captures its exit code and stderr, and asserts the tool exits with a non-zero status while emitting the canonical "GIF-LIB error: Failed to read from given file." diagnostic, anchoring giftool's empty-input failure mode.
# @timeout: 30
# @tags: usage, cli, giftool, error
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

set +e
giftool -d 0 </dev/null >"$tmpdir/out.gif" 2>"$tmpdir/err.txt"
rc=$?
set -e

if (( rc == 0 )); then
  printf 'giftool unexpectedly succeeded on empty stdin\n' >&2
  exit 1
fi

validator_assert_contains "$tmpdir/err.txt" 'GIF-LIB error'
validator_assert_contains "$tmpdir/err.txt" 'Failed to read'

# The output file must be empty: giftool aborted before writing anything.
out_size=$(wc -c <"$tmpdir/out.gif")
if (( out_size != 0 )); then
  printf 'expected empty output on failure, got %s bytes\n' "$out_size" >&2
  exit 1
fi
