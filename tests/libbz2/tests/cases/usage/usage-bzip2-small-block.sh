#!/usr/bin/env bash
# @testcase: usage-bzip2-small-block
# @title: bzip2 small block
# @description: Runs bzip2 client small block behavior through libbz2.
# @timeout: 180
# @tags: usage, compression
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
    trap 'rm -rf "$tmpdir"' EXIT

    printf 'small block payload\n' >"$tmpdir/in.txt"
bzip2 -1 -c "$tmpdir/in.txt" | bzip2 -dc
