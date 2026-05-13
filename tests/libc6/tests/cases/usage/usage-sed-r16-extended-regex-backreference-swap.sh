#!/usr/bin/env bash
# @testcase: usage-sed-r16-extended-regex-backreference-swap
# @title: sed -E swaps two captured groups using \2\1 backreference order
# @description: Uses sed -E to match (a)(b) in the input string "ab" and replace it with \2\1, asserting the result is "ba" — locking in sed's extended-regex backreference numbering against a stable, unambiguous fixture.
# @timeout: 30
# @tags: usage, sed, backreference, extended-regex
# @client: sed

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

out=$(printf 'ab\n' | sed -E 's/(a)(b)/\2\1/')
[[ "$out" == "ba" ]] || {
    printf 'expected ba, got %q\n' "$out" >&2
    exit 1
}
