#!/usr/bin/env bash
# @testcase: usage-bash-r20-printf-percent-o-octal
# @title: bash printf "%o" renders decimal 8 as octal "10"
# @description: Invokes bash printf with format specifier "%o" and decimal argument 8, then asserts the captured output equals the string "10" - locking in libc-backed octal conversion via the bash builtin printf.
# @timeout: 30
# @tags: usage, bash, printf, octal, r20
# @client: bash

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

got=$(bash -c 'printf "%o" 8')
[[ "$got" == "10" ]] || {
    printf 'expected "10", got %q\n' "$got" >&2
    exit 1
}
