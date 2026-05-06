#!/usr/bin/env bash
# @testcase: usage-sed-batch12-y-command-bytewise-translit
# @title: sed y/// transliteration replaces ASCII bytes deterministically
# @description: Uses sed y/// to transliterate a fixed set of ASCII bytes and verifies the exact mapping is applied character by character.
# @timeout: 60
# @tags: usage, sed
# @client: sed

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'abcdef\n' >"$tmpdir/in.txt"
sed 'y/abcdef/123456/' "$tmpdir/in.txt" >"$tmpdir/out.txt"
got=$(cat "$tmpdir/out.txt")
[[ "$got" == "123456" ]]
