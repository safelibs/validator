#!/usr/bin/env bash
# @testcase: usage-bash-array-expansion
# @title: bash array expansion
# @description: Runs bash array expansion and arithmetic through the libc-backed shell runtime.
# @timeout: 180
# @tags: usage, shell
# @client: bash

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bash-array-expansion"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

bash -lc 'values=(alpha beta gamma); printf "%s:%d\n" "${values[1]}" "${#values[@]}"' >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'beta:3'
