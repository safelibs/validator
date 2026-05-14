#!/usr/bin/env bash
# @testcase: usage-python3-r17-re-sub-digits-replaced
# @title: python3 re.sub collapses each digit run into the literal N
# @description: Runs python3 -c with re.sub(r"\d+","N","a1b2c3") and asserts the output is exactly "aNbNcN", locking in the libc-backed regex digit-class behavior on the full python3 stdlib.
# @timeout: 30
# @tags: usage, python3, regex
# @client: python3

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

got=$(python3 -c 'import re; print(re.sub(r"\d+","N","a1b2c3"))')
[[ "$got" == "aNbNcN" ]] || {
    printf 'expected aNbNcN, got %q\n' "$got" >&2
    exit 1
}
