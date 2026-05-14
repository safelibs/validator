#!/usr/bin/env bash
# @testcase: usage-bash-r18-printf-percent-d-padding
# @title: bash printf "%05d" zero-pads a small integer to width five
# @description: Invokes bash printf with format specifier "%05d" and argument 42, then asserts the captured output equals "00042" — locking in libc-backed integer padding in the bash builtin printf.
# @timeout: 30
# @tags: usage, bash, printf, padding, r18
# @client: bash

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

got=$(bash -c 'printf "%05d" 42')
[[ "$got" == "00042" ]] || {
    printf 'expected "00042", got %q\n' "$got" >&2
    exit 1
}
