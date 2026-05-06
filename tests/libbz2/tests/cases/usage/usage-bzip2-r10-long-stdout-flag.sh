#!/usr/bin/env bash
# @testcase: usage-bzip2-r10-long-stdout-flag
# @title: bzip2 --stdout long flag writes compressed bytes to stdout
# @description: Uses bzip2 --stdout to emit a compressed stream to a captured file, leaving the input untouched, and verifies the captured stream round-trips to the original payload.
# @timeout: 60
# @tags: usage, compression, long-flag, stdout
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

for i in $(seq 1 50); do
    printf 'long-stdout payload line %02d\n' "$i"
done >"$tmpdir/in.txt"

orig_sha=$(sha256sum "$tmpdir/in.txt" | awk '{print $1}')

bzip2 --stdout "$tmpdir/in.txt" >"$tmpdir/out.bz2"

[[ -f "$tmpdir/in.txt" ]]
[[ ! -f "$tmpdir/in.txt.bz2" ]]

after_sha=$(sha256sum "$tmpdir/in.txt" | awk '{print $1}')
[[ "$orig_sha" == "$after_sha" ]]

bzip2 -dc "$tmpdir/out.bz2" >"$tmpdir/round"
cmp "$tmpdir/in.txt" "$tmpdir/round"
