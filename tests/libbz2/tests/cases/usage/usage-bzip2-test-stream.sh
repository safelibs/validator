#!/usr/bin/env bash
# @testcase: usage-bzip2-test-stream
# @title: bzip2 test stream
# @description: Runs bzip2 client test stream behavior through libbz2.
# @timeout: 180
# @tags: usage, compression
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
    trap 'rm -rf "$tmpdir"' EXIT

    printf 'integrity\n' >"$tmpdir/in.txt"
bzip2 -c "$tmpdir/in.txt" >"$tmpdir/in.bz2"
bzip2 -tv "$tmpdir/in.bz2"
