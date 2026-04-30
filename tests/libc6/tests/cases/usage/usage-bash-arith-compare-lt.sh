#!/usr/bin/env bash
# @testcase: usage-bash-arith-compare-lt
# @title: bash arithmetic less-than compare
# @description: Uses bash (( a < b )) arithmetic comparison through the libc-backed shell runtime.
# @timeout: 180
# @tags: usage, shell
# @client: bash

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bash-arith-compare-lt"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

bash -lc 'a=3; b=10; if (( a < b )); then printf "lt:%d:%d\n" "$a" "$b"; else printf "ge\n"; fi' >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'lt:3:10'
