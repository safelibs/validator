#!/usr/bin/env bash
# @testcase: usage-sed-r17-pattern-line-deletion
# @title: sed '/PATTERN/d' removes every matching line from a stream
# @description: Pipes a five-line stream through sed '/drop/d' and asserts the output contains exactly the three non-matching lines in their original order — locking in sed's address-driven d command for line deletion.
# @timeout: 30
# @tags: usage, sed, delete
# @client: sed

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.txt" <<'TXT'
keep alpha
drop bravo
keep charlie
drop delta
keep echo
TXT

sed '/drop/d' "$tmpdir/in.txt" >"$tmpdir/out.txt"
got=$(cat "$tmpdir/out.txt")
want='keep alpha
keep charlie
keep echo'
[[ "$got" == "$want" ]] || {
    printf 'sed delete mismatch\n--- want ---\n%s\n--- got ---\n%s\n' "$want" "$got" >&2
    exit 1
}
