#!/usr/bin/env bash
# @testcase: usage-grep-r19-only-matching-token
# @title: grep -o prints only the matched token, one per line
# @description: Runs grep -o against a small text where the pattern "fox" appears three times across two lines, and asserts the captured output is exactly three lines each equal to "fox" - locking in libc-backed regex-only-match extraction.
# @timeout: 30
# @tags: usage, grep, only-matching, r19
# @client: grep

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.txt" <<'TXT'
the fox and the fox
a fox runs
no animal here
TXT

out=$(grep -o 'fox' "$tmpdir/in.txt")
n=$(printf '%s\n' "$out" | wc -l)
[[ "$n" -eq 3 ]] || {
    printf 'expected 3 lines, got %s\n%s\n' "$n" "$out" >&2
    exit 1
}
while IFS= read -r line; do
    [[ "$line" == "fox" ]] || {
        printf 'expected "fox", got %q\n' "$line" >&2
        exit 1
    }
done <<<"$out"
