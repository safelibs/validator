#!/usr/bin/env bash
# @testcase: usage-gawk-r10-tolower-toupper-ascii-roundtrip
# @title: gawk tolower/toupper round-trip ASCII letters under LC_ALL=C
# @description: Pipes mixed-case ASCII through gawk tolower(toupper($0)) under LC_ALL=C and verifies the result equals the lowercase original (libc tolower/toupper path).
# @timeout: 60
# @tags: usage, gawk, locale
# @client: gawk

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'Hello World 123\n' >"$tmpdir/in.txt"
LC_ALL=C gawk '{ print tolower(toupper($0)) }' "$tmpdir/in.txt" >"$tmpdir/out.txt"
got=$(cat "$tmpdir/out.txt")
[[ "$got" == "hello world 123" ]]
