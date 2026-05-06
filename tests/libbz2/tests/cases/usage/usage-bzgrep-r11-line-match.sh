#!/usr/bin/env bash
# @testcase: usage-bzgrep-r11-line-match
# @title: bzgrep -x matches whole lines only, not partial occurrences
# @description: Compresses a payload containing the literal "exact" on a line by itself and the substring "exactly" on another line, then verifies bzgrep -x 'exact' returns only the standalone-line match and excludes the partial-line occurrence.
# @timeout: 60
# @tags: usage, bzgrep, line-match
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.txt" <<'EOF'
exact
exactly there
prefix exact suffix
exact
EOF

bzip2 "$tmpdir/in.txt"

bzgrep -x 'exact' "$tmpdir/in.txt.bz2" >"$tmpdir/out.txt"

# Two standalone-line matches, no partial-line leaks.
[[ "$(wc -l <"$tmpdir/out.txt")" == "2" ]]
[[ "$(grep -Fxc 'exact' "$tmpdir/out.txt")" == "2" ]]
! grep -Fq 'exactly' "$tmpdir/out.txt"
! grep -Fq 'prefix' "$tmpdir/out.txt"
