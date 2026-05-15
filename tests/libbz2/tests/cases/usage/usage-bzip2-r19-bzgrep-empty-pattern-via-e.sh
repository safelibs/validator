#!/usr/bin/env bash
# @testcase: usage-bzip2-r19-bzgrep-empty-pattern-via-e
# @title: bzgrep with -e and a single-character pattern returns every line containing that char
# @description: Compresses a text where two of four lines contain the letter "x", runs bzgrep -e 'x' on the archive, and asserts exactly two matching lines are returned - locking in the -e flag pattern delivery to bzgrep over compressed input.
# @timeout: 30
# @tags: usage, bzgrep, e-flag, r19
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.txt" <<'TXT'
axe in tree
no match here
extra crunchy
plain word
TXT

bzip2 "$tmpdir/in.txt"

got=$(bzgrep -e 'x' "$tmpdir/in.txt.bz2")
n=$(printf '%s\n' "$got" | wc -l)
[[ "$n" -eq 2 ]] || {
    printf 'expected 2 matching lines, got %s\n%s\n' "$n" "$got" >&2
    exit 1
}
