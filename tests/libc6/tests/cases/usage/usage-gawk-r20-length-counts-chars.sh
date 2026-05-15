#!/usr/bin/env bash
# @testcase: usage-gawk-r20-length-counts-chars
# @title: gawk length() returns 11 for the ASCII string "hello world"
# @description: Invokes gawk 'BEGIN{print length("hello world")}' and asserts the captured output is exactly "11" - locking in libc-backed string-length computation through gawk's length() builtin.
# @timeout: 30
# @tags: usage, gawk, length, r20
# @client: gawk

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

got=$(gawk 'BEGIN{print length("hello world")}')
[[ "$got" == "11" ]] || {
    printf 'expected "11", got %q\n' "$got" >&2
    exit 1
}
