#!/usr/bin/env bash
# @testcase: usage-bzip2-custom-suffix-roundtrip
# @title: bzip2 custom suffix round trip
# @description: Exercises bzip2 custom suffix round trip through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bzip2-custom-suffix-roundtrip"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

sample_root="$VALIDATOR_SAMPLE_ROOT"

printf 'custom suffix payload\n' >"$tmpdir/custom.txt"
bzip2 -zk "$tmpdir/custom.txt"
mv "$tmpdir/custom.txt.bz2" "$tmpdir/custom.txt.tbz"
bzip2 -dc "$tmpdir/custom.txt.tbz" >"$tmpdir/out.txt"
validator_assert_contains "$tmpdir/out.txt" 'custom suffix payload'
