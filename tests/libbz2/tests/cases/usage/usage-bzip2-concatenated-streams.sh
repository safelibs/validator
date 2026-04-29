#!/usr/bin/env bash
# @testcase: usage-bzip2-concatenated-streams
# @title: bzip2 concatenated streams
# @description: Runs bzip2 client concatenated streams behavior through libbz2.
# @timeout: 180
# @tags: usage, compression
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
    trap 'rm -rf "$tmpdir"' EXIT

    printf 'one\n' >"$tmpdir/one"; printf 'two\n' >"$tmpdir/two"
bzip2 -c "$tmpdir/one" >"$tmpdir/all.bz2"; bzip2 -c "$tmpdir/two" >>"$tmpdir/all.bz2"
bzip2 -dc "$tmpdir/all.bz2" | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'two'
