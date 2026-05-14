#!/usr/bin/env bash
# @testcase: usage-bzip2-r18-bzcmp-skip2-byte
# @title: bzcmp reports the first differing byte position when comparing two compressed payloads
# @description: Builds two payloads that differ only at offset 5, compresses both, runs bzcmp on the resulting archives without suppression flags, and asserts the output contains "differ: byte" plus a positive byte offset — locking in the human-readable diff line.
# @timeout: 30
# @tags: usage, bzcmp, diff, r18
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'abcdeFghij\n' >"$tmpdir/x"
printf 'abcdeXghij\n' >"$tmpdir/y"
bzip2 "$tmpdir/x" "$tmpdir/y"

set +e
bzcmp "$tmpdir/x.bz2" "$tmpdir/y.bz2" >"$tmpdir/diff" 2>&1
rc=$?
set -e

[[ "$rc" -eq 1 ]] || { printf 'expected rc=1 for differing files, got %s\n' "$rc" >&2; cat "$tmpdir/diff" >&2; exit 1; }
grep -E 'differ: byte [0-9]+' "$tmpdir/diff" >/dev/null || {
    printf 'diff line missing differ: byte N\n' >&2
    cat "$tmpdir/diff" >&2
    exit 1
}
