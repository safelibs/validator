#!/usr/bin/env bash
# @testcase: usage-coreutils-r20-wc-line-count
# @title: wc -l counts five lines in a five-newline file
# @description: Writes five newline-terminated lines to a tempfile and runs wc -l against it, then asserts the leading numeric token is exactly 5 - locking in libc-backed line-count accounting through coreutils wc.
# @timeout: 30
# @tags: usage, coreutils, wc, lines, r20
# @client: coreutils

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'a\nb\nc\nd\ne\n' >"$tmpdir/lines.txt"

n=$(wc -l <"$tmpdir/lines.txt")
[[ "$n" -eq 5 ]] || {
    printf 'expected 5, got %s\n' "$n" >&2
    exit 1
}
