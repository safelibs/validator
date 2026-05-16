#!/usr/bin/env bash
# @testcase: usage-bzip2-r21-bzcat-force-missing-no-args
# @title: bzcat -f on a non-bzip2 file passes through unchanged
# @description: Writes a plain (non-bzip2) text file and runs bzcat -f against it, asserting the captured output equals the source bytes - locking in the -f (force) pass-through behavior of bzcat on uncompressed input, distinct from other -f tests that target bzip2 itself.
# @timeout: 30
# @tags: usage, bzcat, force, passthrough, r21
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'plain-text-not-bzip2\n' >"$tmpdir/plain.txt"

bzcat -f "$tmpdir/plain.txt" >"$tmpdir/out.txt"
cmp -s "$tmpdir/plain.txt" "$tmpdir/out.txt" || {
    echo 'bzcat -f did not pass through plain file unchanged' >&2
    od -An -c <"$tmpdir/plain.txt" >&2
    od -An -c <"$tmpdir/out.txt" >&2
    exit 1
}
