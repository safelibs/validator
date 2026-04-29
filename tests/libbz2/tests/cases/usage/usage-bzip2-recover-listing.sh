#!/usr/bin/env bash
# @testcase: usage-bzip2-recover-listing
# @title: bzip2 recover listing
# @description: Runs bzip2 client recover listing behavior through libbz2.
# @timeout: 180
# @tags: usage, compression
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
    trap 'rm -rf "$tmpdir"' EXIT

    printf 'recover payload\n' >"$tmpdir/in.txt"
bzip2 -c "$tmpdir/in.txt" >"$tmpdir/in.bz2"
( cd "$tmpdir" && bzip2recover in.bz2 ) | tee "$tmpdir/out"
ls "$tmpdir"/rec*.bz2
