#!/usr/bin/env bash
# @testcase: usage-bzip2-r18-bzgrep-files-with-match
# @title: bzgrep -l lists only the archives that contain the pattern
# @description: Compresses two text files where only one contains the search pattern, runs bzgrep -l with both archives, and asserts only the matching archive's path appears on stdout while the non-matching archive does not — locking in the files-with-match flag semantics across multi-file invocation.
# @timeout: 30
# @tags: usage, bzgrep, files-with-match, r18
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'hello world\nanother line\n' >"$tmpdir/hit.txt"
printf 'nothing of interest here\n' >"$tmpdir/miss.txt"
bzip2 "$tmpdir/hit.txt" "$tmpdir/miss.txt"

bzgrep -l 'hello' "$tmpdir/hit.txt.bz2" "$tmpdir/miss.txt.bz2" >"$tmpdir/out"

grep -F 'hit.txt.bz2' "$tmpdir/out" >/dev/null || {
    printf 'expected hit.txt.bz2 in listing\n' >&2
    cat "$tmpdir/out" >&2
    exit 1
}
! grep -F 'miss.txt.bz2' "$tmpdir/out"
