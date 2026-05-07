#!/usr/bin/env bash
# @testcase: usage-bzip2-r14-bzmore-through-cat-pipe
# @title: bzmore output piped through cat preserves payload bytes
# @description: Compresses a multi-line payload, runs "bzmore" with stdin tied to /dev/null and stdout piped through cat, asserts the captured output contains every source line marker. Distinct from the r13 bzmore pipe-decode case by validating ALL lines (10) rather than two markers.
# @timeout: 60
# @tags: usage, bzmore, pipeline
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

for i in $(seq 1 10); do
    printf 'bzmore-pipe-line-%02d\n' "$i"
done >"$tmpdir/in.txt"

bzip2 "$tmpdir/in.txt"
[[ -f "$tmpdir/in.txt.bz2" ]]

bzmore "$tmpdir/in.txt.bz2" </dev/null | cat >"$tmpdir/out.txt"

for i in $(seq 1 10); do
    grep -F "$(printf 'bzmore-pipe-line-%02d' "$i")" "$tmpdir/out.txt" >/dev/null
done
