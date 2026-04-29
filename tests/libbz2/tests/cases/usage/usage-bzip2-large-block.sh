#!/usr/bin/env bash
# @testcase: usage-bzip2-large-block
# @title: bzip2 large block
# @description: Runs bzip2 client large block behavior through libbz2.
# @timeout: 180
# @tags: usage, compression
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
    trap 'rm -rf "$tmpdir"' EXIT

    for i in $(seq 1 200); do
        printf 'payload %03d\n' "$i"
    done >"$tmpdir/in.txt"
bzip2 -9 -c "$tmpdir/in.txt" >"$tmpdir/in.bz2"
bzip2 -dc "$tmpdir/in.bz2" | wc -l
