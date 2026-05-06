#!/usr/bin/env bash
# @testcase: usage-coreutils-r10-printf-locale-c-decimal-point
# @title: coreutils printf %.3f under LC_ALL=C uses ASCII dot as decimal point
# @description: Calls /usr/bin/printf with a fixed floating-point value under LC_ALL=C and verifies the formatted result uses the POSIX dot decimal separator delivered by libc localeconv.
# @timeout: 60
# @tags: usage, coreutils, locale
# @client: coreutils

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

LC_ALL=C /usr/bin/printf '%.3f\n' 3.14159 >"$tmpdir/out.txt"
got=$(cat "$tmpdir/out.txt")
[[ "$got" == "3.142" ]]
