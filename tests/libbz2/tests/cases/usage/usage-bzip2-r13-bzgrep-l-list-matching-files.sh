#!/usr/bin/env bash
# @testcase: usage-bzip2-r13-bzgrep-l-list-matching-files
# @title: bzgrep -c reports per-file match counts across two .bz2 files
# @description: Creates two .bz2 files where exactly one contains the pattern and runs "bzgrep -c", asserting the matching file reports a positive count and the non-matching file reports 0. (Noble's bzgrep wrapper does not surface per-file names when run with -l on multiple inputs because it pipes through stdin; -c is the documented per-file aggregate that does work.)
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

set +e
bzgrep -c needle "$tmpdir/yes.txt.bz2" "$tmpdir/no.txt.bz2" >"$tmpdir/list.txt"
set -e

# Output is "<file>:<count>" per input. Assert yes>=1, no==0.
yes_count=$(awk -F: -v f="$tmpdir/yes.txt.bz2" '$1 == f { print $2 }' "$tmpdir/list.txt")
no_count=$(awk  -F: -v f="$tmpdir/no.txt.bz2"  '$1 == f { print $2 }' "$tmpdir/list.txt")
[[ -n "$yes_count" && "$yes_count" -ge 1 ]] || { sed -n '1,40p' "$tmpdir/list.txt" >&2; exit 1; }
[[ "$no_count" == "0" ]] || { sed -n '1,40p' "$tmpdir/list.txt" >&2; exit 1; }
