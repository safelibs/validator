#!/usr/bin/env bash
# @testcase: usage-bzip2-stdout-stream
# @title: bzip2 stdout stream
# @description: Runs bzip2 client stdout stream behavior through libbz2.
# @timeout: 180
# @tags: usage, compression
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
    trap 'rm -rf "$tmpdir"' EXIT

    printf 'pipe payload\n' | bzip2 -c | bzip2 -dc | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'pipe payload'
