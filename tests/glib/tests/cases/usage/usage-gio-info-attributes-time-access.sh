#!/usr/bin/env bash
# @testcase: usage-gio-info-attributes-time-access
# @title: gio info reports time access attribute
# @description: Queries the time::access attribute through gio info and verifies the namespace appears in the output.
# @timeout: 180
# @tags: usage, gio, metadata
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gio-info-attributes-time-access"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'access-time payload\n' >"$tmpdir/input.txt"
# Touch the file to give it a definite atime.
touch -a -t 202401021530.45 "$tmpdir/input.txt"

gio info --attributes=time::access "$tmpdir/input.txt" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'time::access'
validator_assert_contains "$tmpdir/out" 'input.txt'
