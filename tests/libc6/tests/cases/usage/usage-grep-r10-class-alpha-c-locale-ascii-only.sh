#!/usr/bin/env bash
# @testcase: usage-grep-r10-class-alpha-c-locale-ascii-only
# @title: grep [[:alpha:]] under LC_ALL=C matches only ASCII letters
# @description: Greps a mixed ASCII-letter and digit-and-punctuation input under LC_ALL=C using the POSIX [[:alpha:]] class and verifies only ASCII letter lines match (libc isalpha under POSIX locale).
# @timeout: 60
# @tags: usage, grep, locale
# @client: grep

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.txt" <<'EOF'
hello
12345
@@@@@
World
777-abc
EOF

LC_ALL=C grep -E '^[[:alpha:]]+$' "$tmpdir/in.txt" >"$tmpdir/out.txt"
LC_ALL=C cat >"$tmpdir/want.txt" <<'EOF'
hello
World
EOF

diff -u "$tmpdir/want.txt" "$tmpdir/out.txt"
