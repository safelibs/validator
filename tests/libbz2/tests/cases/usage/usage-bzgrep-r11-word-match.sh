#!/usr/bin/env bash
# @testcase: usage-bzgrep-r11-word-match
# @title: bzgrep -w matches whole words and rejects substrings
# @description: Compresses a payload containing the substrings "cat" and "category" and verifies bzgrep -w 'cat' prints only the line where "cat" appears as a whole word, with the word-boundary substring match excluded from the output.
# @timeout: 60
# @tags: usage, bzgrep, word-match
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.txt" <<'EOF'
cat sleeps
category list
the cat naps
prefix-category
EOF

bzip2 "$tmpdir/in.txt"

bzgrep -w 'cat' "$tmpdir/in.txt.bz2" >"$tmpdir/out.txt"

# Only the two lines containing "cat" as a whole word.
[[ "$(wc -l <"$tmpdir/out.txt")" == "2" ]]
grep -Fxq 'cat sleeps' "$tmpdir/out.txt"
grep -Fxq 'the cat naps' "$tmpdir/out.txt"
# "category" lines must not leak through.
! grep -F 'category' "$tmpdir/out.txt" >/dev/null
