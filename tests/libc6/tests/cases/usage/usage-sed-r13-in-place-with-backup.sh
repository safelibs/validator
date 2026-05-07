#!/usr/bin/env bash
# @testcase: usage-sed-r13-in-place-with-backup
# @title: sed -i with backup suffix rewrites file in place and preserves a .bak copy
# @description: Writes a fixed input file, runs sed --in-place=.bak with a substitution, and asserts the modified file contains the substitution while a sibling .bak file holds the original bytes verbatim.
# @timeout: 60
# @tags: usage, sed, in-place, backup
# @client: sed

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'apple\nbanana\ncherry\n' >"$tmpdir/in.txt"
cp "$tmpdir/in.txt" "$tmpdir/orig.txt"

LC_ALL=C sed --in-place=.bak 's/banana/BANANA/' "$tmpdir/in.txt"

modified=$(cat "$tmpdir/in.txt")
[[ "$modified" == $'apple\nBANANA\ncherry' ]]

# Backup file must equal the original content byte-for-byte.
cmp "$tmpdir/in.txt.bak" "$tmpdir/orig.txt"
