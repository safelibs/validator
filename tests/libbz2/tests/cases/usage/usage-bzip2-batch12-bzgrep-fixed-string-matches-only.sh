#!/usr/bin/env bash
# @testcase: usage-bzip2-batch12-bzgrep-fixed-string-matches-only
# @title: bzgrep -F treats pattern as fixed string with regex metacharacters
# @description: Compresses a file containing both a literal "a.b" and a string matching the regex a.b (ax3b), then verifies bzgrep -F "a.b" matches only the literal line.
# @timeout: 60
# @tags: usage, compression, bzgrep
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.txt" <<'EOF'
literal a.b
regex ax3b match
not relevant
EOF

bzip2 -c "$tmpdir/in.txt" >"$tmpdir/in.txt.bz2"

bzgrep -F 'a.b' "$tmpdir/in.txt.bz2" >"$tmpdir/match.txt"
count=$(wc -l <"$tmpdir/match.txt")
[[ "$count" == 1 ]]
validator_assert_contains "$tmpdir/match.txt" 'literal a.b'
