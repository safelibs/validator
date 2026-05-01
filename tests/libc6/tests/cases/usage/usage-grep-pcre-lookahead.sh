#!/usr/bin/env bash
# @testcase: usage-grep-pcre-lookahead
# @title: grep -P positive lookahead
# @description: Matches a token followed by a specific suffix using a PCRE positive lookahead and confirms only the prefix portion is reported by grep -oP.
# @timeout: 60
# @tags: usage, grep, regex
# @client: grep

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-grep-pcre-lookahead"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.txt" <<'EOF'
file1.bak
file2.txt
file3.bak
file4.log
EOF

LC_ALL=C.UTF-8 grep -oP '\w+(?=\.bak$)' "$tmpdir/in.txt" >"$tmpdir/out"
printf 'file1\nfile3\n' >"$tmpdir/expected"
cmp "$tmpdir/expected" "$tmpdir/out"
