#!/usr/bin/env bash
# @testcase: usage-gawk-r18-sprintf-precision-float
# @title: gawk sprintf "%.3f" rounds a float to three decimals
# @description: Invokes gawk with BEGIN { printf "%.3f\n", 1.23456789 } and asserts the output equals "1.235" — locking in libc-backed float formatting in gawk's printf.
# @timeout: 30
# @tags: usage, gawk, printf, float, r18
# @client: gawk

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

got=$(LC_ALL=C gawk 'BEGIN { printf "%.3f\n", 1.23456789 }')
[[ "$got" == "1.235" ]] || {
    printf 'expected "1.235", got %q\n' "$got" >&2
    exit 1
}
