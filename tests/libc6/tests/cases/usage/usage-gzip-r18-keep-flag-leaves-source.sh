#!/usr/bin/env bash
# @testcase: usage-gzip-r18-keep-flag-leaves-source
# @title: gzip -k retains the original file alongside the .gz output
# @description: Creates a small text file, runs gzip -k against it, and asserts both the original file and the new .gz archive coexist in the working directory — locking in the keep-flag's non-destructive contract.
# @timeout: 30
# @tags: usage, gzip, keep, r18
# @client: gzip

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'keepable content\n' >"$tmpdir/p.txt"

gzip -k "$tmpdir/p.txt"

[[ -f "$tmpdir/p.txt" ]] || { printf 'expected original p.txt to survive\n' >&2; exit 1; }
[[ -f "$tmpdir/p.txt.gz" ]] || { printf 'expected p.txt.gz to exist\n' >&2; exit 1; }

# Verify the .gz decompresses to the original content.
gunzip -c "$tmpdir/p.txt.gz" >"$tmpdir/back.txt"
diff "$tmpdir/p.txt" "$tmpdir/back.txt"
