#!/usr/bin/env bash
# @testcase: usage-bash-readarray-lines-batch11
# @title: bash readarray lines
# @description: Reads lines with bash readarray and verifies array indexing.
# @timeout: 180
# @tags: usage, shell, libc
# @client: bash

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bash-readarray-lines-batch11"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'alpha\nbeta\n' >"$tmpdir/in.txt"
bash -c 'readarray -t rows <"$1"; printf "%s:%s\n" "${#rows[@]}" "${rows[1]}"' _ "$tmpdir/in.txt" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" '2:beta'
