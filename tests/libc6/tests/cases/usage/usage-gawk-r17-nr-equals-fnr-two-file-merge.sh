#!/usr/bin/env bash
# @testcase: usage-gawk-r17-nr-equals-fnr-two-file-merge
# @title: gawk NR==FNR captures the first file's keys then projects from the second
# @description: Builds two files keyed by their first field, feeds them to gawk in order, and uses the canonical NR==FNR idiom to store the first file's values then emit matched values from the second file — locking in awk's two-pass file-merge semantics.
# @timeout: 30
# @tags: usage, gawk, two-file-merge
# @client: gawk

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/keys.txt" <<'TXT'
alpha 1
bravo 2
charlie 3
TXT

cat >"$tmpdir/lookup.txt" <<'TXT'
alpha
charlie
delta
bravo
TXT

got=$(gawk 'NR==FNR{m[$1]=$2; next} ($1 in m){print $1"="m[$1]}' "$tmpdir/keys.txt" "$tmpdir/lookup.txt")
want='alpha=1
charlie=3
bravo=2'
[[ "$got" == "$want" ]] || {
    printf 'merge mismatch\n--- want ---\n%s\n--- got ---\n%s\n' "$want" "$got" >&2
    exit 1
}
