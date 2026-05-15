#!/usr/bin/env bash
# @testcase: usage-bash-r19-printf-percent-x-hex
# @title: bash printf "%x" renders a small integer as lowercase hex without leading zero
# @description: Invokes bash printf with format specifier "%x" and argument 255, then asserts the captured output equals the string "ff" - locking in libc-backed lowercase hex conversion via the bash builtin printf.
# @timeout: 30
# @tags: usage, bash, printf, hex, r19
# @client: bash

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

got=$(bash -c 'printf "%x" 255')
[[ "$got" == "ff" ]] || {
    printf 'expected "ff", got %q\n' "$got" >&2
    exit 1
}
