#!/usr/bin/env bash
# @testcase: usage-bzip2-r20-bzgrep-matches-anchor-start
# @title: bzgrep with a start-anchor pattern returns only lines beginning with the token
# @description: Compresses a text where two of four lines start with the literal "ERROR " (the rest contain it mid-line or not at all), runs bzgrep '^ERROR ' on the archive, and asserts exactly two matching lines are returned with both starting with "ERROR ", exercising start-of-line anchoring through bzgrep on compressed input distinct from prior fixed-string, word-boundary, or empty-pattern tests.
# @timeout: 30
# @tags: usage, bzgrep, anchor, r20
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/log.txt" <<'TXT'
ERROR something broke
info: ERROR mid-line not match
ERROR another problem
no error here at all
TXT

bzip2 "$tmpdir/log.txt"

got=$(bzgrep '^ERROR ' "$tmpdir/log.txt.bz2")
n=$(printf '%s\n' "$got" | wc -l)
[[ "$n" -eq 2 ]] || {
    printf 'expected 2 anchored matches, got %s:\n%s\n' "$n" "$got" >&2
    exit 1
}

# Verify each match begins with the anchor token
while IFS= read -r line; do
    case "$line" in
        "ERROR "*) ;;
        *)
            printf 'unexpected non-anchored line: %s\n' "$line" >&2
            exit 1
            ;;
    esac
done <<<"$got"
