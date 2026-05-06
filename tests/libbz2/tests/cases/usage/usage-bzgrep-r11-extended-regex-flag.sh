#!/usr/bin/env bash
# @testcase: usage-bzgrep-r11-extended-regex-flag
# @title: bzgrep -E enables extended regex alternation
# @description: Compresses a payload with three distinct lines and verifies bzgrep -E '(apple|cherry)' selects exactly the two lines matching either alternative while skipping the unrelated line, exercising the extended-regex alternation operator that BRE would treat as literal characters.
# @timeout: 60
# @tags: usage, bzgrep, extended-regex
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.txt" <<'EOF'
apple pie
banana split
cherry tart
EOF

bzip2 "$tmpdir/in.txt"

bzgrep -E '(apple|cherry)' "$tmpdir/in.txt.bz2" >"$tmpdir/out.txt"

[[ "$(wc -l <"$tmpdir/out.txt")" == "2" ]]
grep -Fxq 'apple pie' "$tmpdir/out.txt"
grep -Fxq 'cherry tart' "$tmpdir/out.txt"
! grep -Fq 'banana' "$tmpdir/out.txt"
