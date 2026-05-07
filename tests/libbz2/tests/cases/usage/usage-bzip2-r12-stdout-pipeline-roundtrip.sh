#!/usr/bin/env bash
# @testcase: usage-bzip2-r12-stdout-pipeline-roundtrip
# @title: bzip2 -c | bunzip2 -c pipeline preserves bytes exactly
# @description: Pipes the input through bzip2 -c into bunzip2 -c in a single shell pipeline and verifies the round-trip output matches the source bytes via sha256, with no on-disk artifacts beyond the input.
# @timeout: 60
# @tags: usage, pipeline, roundtrip
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

for i in $(seq 1 250); do
    printf 'pipeline payload row %03d\n' "$i"
done >"$tmpdir/in.txt"
orig_sha=$(sha256sum "$tmpdir/in.txt" | awk '{print $1}')

bzip2 -c "$tmpdir/in.txt" | bunzip2 -c >"$tmpdir/out.txt"

out_sha=$(sha256sum "$tmpdir/out.txt" | awk '{print $1}')
[[ "$orig_sha" == "$out_sha" ]]

# .bz2 sibling not produced because -c.
[[ ! -e "$tmpdir/in.txt.bz2" ]]
