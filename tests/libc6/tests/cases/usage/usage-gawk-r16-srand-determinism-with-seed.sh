#!/usr/bin/env bash
# @testcase: usage-gawk-r16-srand-determinism-with-seed
# @title: gawk srand(SEED) makes rand() output deterministic across two invocations
# @description: Calls gawk BEGIN{srand(1);print rand()} twice and asserts the two outputs are identical floating-point strings, locking in gawk's seeded PRNG determinism.
# @timeout: 30
# @tags: usage, gawk, srand, determinism
# @client: gawk

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

a=$(gawk 'BEGIN{srand(1);print rand()}')
b=$(gawk 'BEGIN{srand(1);print rand()}')
[[ "$a" == "$b" ]] || {
    printf 'gawk seeded rand mismatch: %s vs %s\n' "$a" "$b" >&2
    exit 1
}
# Result must look like a number between 0 and 1 inclusive.
[[ "$a" =~ ^0(\.[0-9]+)?$|^1$ ]]
