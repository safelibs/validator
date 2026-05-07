#!/usr/bin/env bash
# @testcase: usage-bash-r12-printf-asterisk-width
# @title: bash printf %*d takes width from argument list via libc
# @description: Uses bash builtin printf with %*d to read the field width dynamically from the next argument and verifies the produced string is right-justified in a 6-column field via libc.
# @timeout: 60
# @tags: usage, bash, printf, libc
# @client: bash

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

LC_ALL=C printf '[%*d]\n' 6 42 >"$tmpdir/out.txt"
got=$(cat "$tmpdir/out.txt")
[[ "$got" == "[    42]" ]]
