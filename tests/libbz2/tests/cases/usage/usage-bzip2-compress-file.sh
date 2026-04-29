#!/usr/bin/env bash
# @testcase: usage-bzip2-compress-file
# @title: bzip2 compress file
# @description: Runs bzip2 client compress file behavior through libbz2.
# @timeout: 180
# @tags: usage, compression
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
    trap 'rm -rf "$tmpdir"' EXIT

    printf 'alpha beta\n' >"$tmpdir/in.txt"
bzip2 -k "$tmpdir/in.txt"
bzip2 -dc "$tmpdir/in.txt.bz2" | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'alpha beta'
