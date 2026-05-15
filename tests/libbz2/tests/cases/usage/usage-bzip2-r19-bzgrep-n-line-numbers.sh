#!/usr/bin/env bash
# @testcase: usage-bzip2-r19-bzgrep-n-line-numbers
# @title: bzgrep -n prefixes matching lines with the original 1-based line number
# @description: Compresses a six-line text where the match falls on line 4, runs bzgrep -n 'target' on the archive, and asserts the captured output begins with "4:" - locking in line-number prefixing of bzgrep over the original (uncompressed) line offsets.
# @timeout: 30
# @tags: usage, bzgrep, line-number, r19
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.txt" <<'TXT'
alpha
beta
gamma
target line here
delta
epsilon
TXT

bzip2 "$tmpdir/in.txt"

got=$(bzgrep -n 'target' "$tmpdir/in.txt.bz2")
case "$got" in
    "4:target line here") ;;
    *) printf 'expected "4:target line here", got %q\n' "$got" >&2; exit 1 ;;
esac
