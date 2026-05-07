#!/usr/bin/env bash
# @testcase: usage-bzip2-r13-bzgrep-l-list-matching-files
# @title: bzgrep -l prints only filenames of bz2 files containing the pattern
# @description: Creates two .bz2 files where exactly one contains the pattern and runs "bzgrep -l", asserting the output is the single matching filename and the non-matching file is absent from the listing.
# @timeout: 60
# @tags: usage, bzgrep, list
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'this contains needle here\nordinary line\n' >"$tmpdir/yes.txt"
printf 'no match content\nplain line\n' >"$tmpdir/no.txt"

bzip2 "$tmpdir/yes.txt" "$tmpdir/no.txt"
[[ -f "$tmpdir/yes.txt.bz2" && -f "$tmpdir/no.txt.bz2" ]]

bzgrep -l needle "$tmpdir/yes.txt.bz2" "$tmpdir/no.txt.bz2" >"$tmpdir/list.txt"

# Output should mention the yes file and not the no file.
grep -F "$tmpdir/yes.txt.bz2" "$tmpdir/list.txt" >/dev/null
! grep -F "$tmpdir/no.txt.bz2" "$tmpdir/list.txt"
[[ "$(wc -l <"$tmpdir/list.txt")" -eq 1 ]]
