#!/usr/bin/env bash
# @testcase: usage-gawk-r19-substr-extract-bytes
# @title: gawk substr() extracts a fixed range of characters from a record
# @description: Pipes a known string into gawk and prints substr($0, 8, 5), then asserts the captured token equals the expected slice - locking in libc-backed substring extraction via the gawk runtime.
# @timeout: 30
# @tags: usage, gawk, substr, r19
# @client: gawk

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

got=$(printf 'abcdefghijklmnop\n' | gawk '{ print substr($0, 8, 5) }')
[[ "$got" == "hijkl" ]] || {
    printf 'expected "hijkl", got %q\n' "$got" >&2
    exit 1
}
