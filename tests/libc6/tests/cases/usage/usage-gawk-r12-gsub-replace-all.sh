#!/usr/bin/env bash
# @testcase: usage-gawk-r12-gsub-replace-all
# @title: gawk gsub() replaces every regex match in the record
# @description: Uses gawk gsub() with a digit-class regex to replace every digit in the input with a hash character and asserts the count of substitutions and the rewritten record.
# @timeout: 60
# @tags: usage, gawk, regex, gsub
# @client: gawk

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'a1b2c3d4\n' >"$tmpdir/in.txt"
LC_ALL=C gawk '{ n = gsub(/[0-9]/, "#"); printf("%d %s\n", n, $0) }' "$tmpdir/in.txt" >"$tmpdir/got.txt"
got=$(cat "$tmpdir/got.txt")
[[ "$got" == "4 a#b#c#d#" ]]
