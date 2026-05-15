#!/usr/bin/env bash
# @testcase: usage-grep-r20-ignore-case-mixed-input
# @title: grep -i matches a lowercase pattern against mixed-case input lines
# @description: Builds a three-line file with mixed-case content (Hello, HELLO, world), runs grep -i hello, and asserts exactly two lines match - locking in libc-backed case-insensitive matching via grep -i.
# @timeout: 30
# @tags: usage, grep, ignore-case, r20
# @client: grep

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.txt" <<'EOF'
Hello
HELLO
world
EOF

n=$(LC_ALL=C grep -ci 'hello' "$tmpdir/in.txt")
[[ "$n" -eq 2 ]] || {
    printf 'expected 2 case-insensitive matches, got %s\n' "$n" >&2
    exit 1
}
