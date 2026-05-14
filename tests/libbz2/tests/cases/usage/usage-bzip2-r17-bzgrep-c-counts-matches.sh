#!/usr/bin/env bash
# @testcase: usage-bzip2-r17-bzgrep-c-counts-matches
# @title: bzgrep -c reports the integer count of matches inside a bz2 archive
# @description: Builds a bz2 archive whose decompressed body contains exactly four "needle" lines among other content, runs bzgrep -c against it, and asserts the lone stdout token is the integer 4 — locking in the -c count-mode output shape.
# @timeout: 60
# @tags: usage, bzgrep, count
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/payload.txt" <<'TXT'
needle one
unrelated
needle two
filler
needle three
also-filler
needle four
final
TXT

bzip2 "$tmpdir/payload.txt"
got=$(bzgrep -c 'needle' "$tmpdir/payload.txt.bz2")
[[ "$got" == "4" ]] || {
    printf 'expected bzgrep -c == 4, got %q\n' "$got" >&2
    exit 1
}
