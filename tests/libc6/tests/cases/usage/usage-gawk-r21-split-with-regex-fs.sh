#!/usr/bin/env bash
# @testcase: usage-gawk-r21-split-with-regex-fs
# @title: gawk split() with a regex separator returns the expected field count
# @description: Runs gawk split($0, a, /[,;]/) on the input "one,two;three,four" and asserts the returned field count is 4 and a[3] equals "three" - locking in split()'s regex-separator behavior which is distinct from default FS field-splitting tests.
# @timeout: 30
# @tags: usage, gawk, split, regex, r21
# @client: gawk

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

got=$(printf 'one,two;three,four\n' | gawk '{ n=split($0, a, /[,;]/); printf "n=%d third=%s\n", n, a[3] }')
[[ "$got" == "n=4 third=three" ]] || {
    printf 'expected "n=4 third=three", got %q\n' "$got" >&2
    exit 1
}
