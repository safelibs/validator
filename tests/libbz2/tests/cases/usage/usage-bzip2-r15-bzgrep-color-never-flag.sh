#!/usr/bin/env bash
# @testcase: usage-bzip2-r15-bzgrep-color-never-flag
# @title: bzgrep --color=never emits matches without ANSI escape sequences
# @description: Builds a .bz2 archive containing a payload with one obvious match, runs "bzgrep --color=never apple file.bz2", and asserts the output is non-empty, contains the literal match line, and contains zero ESC (0x1b) bytes — confirming the --color=never flag is forwarded through bzgrep to grep without leaking color escapes.
# @timeout: 60
# @tags: usage, bzgrep, color
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

{
    printf 'apple line one\n'
    printf 'banana split\n'
    printf 'cherry tart\n'
} >"$tmpdir/data.txt"

bzip2 "$tmpdir/data.txt"
[[ -f "$tmpdir/data.txt.bz2" ]]

bzgrep --color=never apple "$tmpdir/data.txt.bz2" >"$tmpdir/out.txt"

[[ -s "$tmpdir/out.txt" ]]
grep -Fq 'apple line one' "$tmpdir/out.txt"

# Zero ESC (0x1b) bytes in the output.
esc_count=$(tr -dc '\033' <"$tmpdir/out.txt" | wc -c)
test "$esc_count" = "0"
