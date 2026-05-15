#!/usr/bin/env bash
# @testcase: usage-bzip2-r19-bzgrep-w-word-boundary
# @title: bzgrep -w matches a whole word and skips substring-only occurrences
# @description: Compresses a small text file containing the tokens "cat", "catalog", and "scatter" on separate lines with bzip2, runs bzgrep -w 'cat' on the archive, and asserts the output contains the bare-word line but not the substring lines - locking in word-boundary matching on compressed input.
# @timeout: 30
# @tags: usage, bzgrep, word-boundary, r19
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.txt" <<'TXT'
cat
catalog of books
scatter the seeds
black cat sat
TXT

bzip2 "$tmpdir/in.txt"

got=$(bzgrep -w 'cat' "$tmpdir/in.txt.bz2")

printf '%s\n' "$got" | grep -Fxq 'cat' || {
    printf 'expected bare-word line "cat", got:\n%s\n' "$got" >&2
    exit 1
}
printf '%s\n' "$got" | grep -Fxq 'black cat sat' || {
    printf 'expected "black cat sat", got:\n%s\n' "$got" >&2
    exit 1
}
if printf '%s\n' "$got" | grep -Fq 'catalog'; then
    printf 'unexpected substring match for "catalog":\n%s\n' "$got" >&2
    exit 1
fi
if printf '%s\n' "$got" | grep -Fq 'scatter'; then
    printf 'unexpected substring match for "scatter":\n%s\n' "$got" >&2
    exit 1
fi
