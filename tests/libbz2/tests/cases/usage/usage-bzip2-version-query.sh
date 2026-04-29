#!/usr/bin/env bash
# @testcase: usage-bzip2-version-query
# @title: bzip2 version query
# @description: Runs bzip2 client version query behavior through libbz2.
# @timeout: 180
# @tags: usage, compression
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
    trap 'rm -rf "$tmpdir"' EXIT

    bzip2 --version 2>&1 | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'bzip2'
