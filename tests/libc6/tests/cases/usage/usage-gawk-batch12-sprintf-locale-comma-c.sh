#!/usr/bin/env bash
# @testcase: usage-gawk-batch12-sprintf-locale-comma-c
# @title: gawk sprintf %.2f under LC_ALL=C uses dot decimal
# @description: Uses gawk sprintf with %.2f under LC_ALL=C and verifies the formatted result uses a dot as decimal separator (libc lconv default for C locale).
# @timeout: 60
# @tags: usage, gawk, locale
# @client: gawk

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

LC_ALL=C gawk 'BEGIN { printf("%.2f\n", 12345.678) }' >"$tmpdir/out.txt"
got=$(cat "$tmpdir/out.txt")
[[ "$got" == "12345.68" ]]
