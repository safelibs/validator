#!/usr/bin/env bash
# @testcase: usage-grep-r17-after-context-two-lines
# @title: grep -A 2 emits two post-match context lines after a hit
# @description: Builds a five-line file with a single "needle" anchor, runs grep -A 2 against it, and asserts the output is exactly the anchor plus the two following lines in order — locking in libc-backed grep post-context selection.
# @timeout: 30
# @tags: usage, grep, after-context
# @client: grep

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.txt" <<'TXT'
prefix-one
prefix-two
needle anchor
post-one
post-two
post-three
TXT

grep -A 2 'needle' "$tmpdir/in.txt" >"$tmpdir/out.txt"
got=$(cat "$tmpdir/out.txt")
want='needle anchor
post-one
post-two'
[[ "$got" == "$want" ]] || {
    printf 'after-context mismatch\n--- want ---\n%s\n--- got ---\n%s\n' "$want" "$got" >&2
    exit 1
}
