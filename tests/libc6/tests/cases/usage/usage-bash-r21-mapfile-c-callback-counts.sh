#!/usr/bin/env bash
# @testcase: usage-bash-r21-mapfile-c-callback-counts
# @title: bash mapfile -t reads four lines into an array of length 4
# @description: Pipes a four-line heredoc into bash mapfile -t and asserts the resulting array length is exactly 4 and the third element equals "gamma" - locking in the line-stripping (-t) and array-size contract of mapfile distinct from existing -d and -n tests.
# @timeout: 30
# @tags: usage, bash, mapfile, r21
# @client: bash

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

out=$(bash -c '
mapfile -t arr <<EOF
alpha
beta
gamma
delta
EOF
printf "len=%d\n" "${#arr[@]}"
printf "third=%s\n" "${arr[2]}"
')

validator_assert_contains <(printf '%s\n' "$out") 'len=4'
validator_assert_contains <(printf '%s\n' "$out") 'third=gamma'
