#!/usr/bin/env bash
# @testcase: usage-bash-r12-printf-hex-format-padded
# @title: bash printf %08x zero-pads hex output via libc snprintf
# @description: Uses bash builtin printf to format an integer as zero-padded 8-digit hex via libc snprintf and asserts the exact lowercase output for 255 and 4096.
# @timeout: 60
# @tags: usage, bash, printf, libc
# @client: bash

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

LC_ALL=C printf '%08x %08x\n' 255 4096 >"$tmpdir/out.txt"
got=$(cat "$tmpdir/out.txt")
[[ "$got" == "000000ff 00001000" ]]
