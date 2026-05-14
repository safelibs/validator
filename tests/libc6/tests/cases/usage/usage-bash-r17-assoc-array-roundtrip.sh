#!/usr/bin/env bash
# @testcase: usage-bash-r17-assoc-array-roundtrip
# @title: bash associative array stores and retrieves a key-value pair
# @description: Declares an associative array via declare -A, assigns a value under a string key, and asserts the indexed read returns the original value byte-for-byte, locking in the bash 5.x associative-array surface on noble.
# @timeout: 30
# @tags: usage, bash, assoc-array
# @client: bash

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

got=$(bash -c 'declare -A m; m[alpha]=bravo; m[charlie-delta]="echo foxtrot"; printf "%s|%s\n" "${m[alpha]}" "${m[charlie-delta]}"')
[[ "$got" == "bravo|echo foxtrot" ]] || {
    printf 'expected "bravo|echo foxtrot", got %q\n' "$got" >&2
    exit 1
}
