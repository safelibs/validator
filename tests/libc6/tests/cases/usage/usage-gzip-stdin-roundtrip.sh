#!/usr/bin/env bash
# @testcase: usage-gzip-stdin-roundtrip
# @title: gzip stdin round trip
# @description: Exercises gzip stdin round trip through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: gzip

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gzip-stdin-roundtrip"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'gzip stdin payload\n' | gzip -c | gzip -dc >"$tmpdir/out.txt"
validator_assert_contains "$tmpdir/out.txt" 'gzip stdin payload'
