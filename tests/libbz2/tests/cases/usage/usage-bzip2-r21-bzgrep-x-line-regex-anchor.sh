#!/usr/bin/env bash
# @testcase: usage-bzip2-r21-bzgrep-x-line-regex-anchor
# @title: bzgrep -x matches only when the pattern spans the entire line
# @description: Compresses a four-line payload containing both partial and full matches of a token, runs bzgrep -x 'token' and asserts only the line equal to 'token' is reported - locking in the -x whole-line match semantics specifically (existing bzgrep tests cover -F / -w / -E but not -x line anchoring).
# @timeout: 30
# @tags: usage, bzgrep, line-regex, r21
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.txt" <<'EOF'
token-prefix
token
suffix-token
prefix-token-suffix
EOF

bzip2 "$tmpdir/in.txt"
bzgrep -x 'token' "$tmpdir/in.txt.bz2" >"$tmpdir/out.txt"

n=$(wc -l <"$tmpdir/out.txt")
[[ "$n" -eq 1 ]] || { printf 'expected 1 line, got %s\n' "$n" >&2; cat "$tmpdir/out.txt" >&2; exit 1; }
got=$(cat "$tmpdir/out.txt")
[[ "$got" == "token" ]] || { printf 'expected exact match "token", got %q\n' "$got" >&2; exit 1; }
