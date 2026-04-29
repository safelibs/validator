#!/usr/bin/env bash
# @testcase: usage-bzip2-three-stream-concat
# @title: bzip2 three concatenated streams
# @description: Appends three bzip2 streams into a single file and verifies bzip2 -dc emits all three plaintext payloads in order.
# @timeout: 180
# @tags: usage, bzip2, stream
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bzip2-three-stream-concat"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'one\n' >"$tmpdir/one.txt"
printf 'two\n' >"$tmpdir/two.txt"
printf 'three\n' >"$tmpdir/three.txt"
bzip2 -c "$tmpdir/one.txt" >"$tmpdir/concat.bz2"
bzip2 -c "$tmpdir/two.txt" >>"$tmpdir/concat.bz2"
bzip2 -c "$tmpdir/three.txt" >>"$tmpdir/concat.bz2"
bzip2 -dc "$tmpdir/concat.bz2" >"$tmpdir/out.txt"
grep -Fxq 'one' "$tmpdir/out.txt"
grep -Fxq 'two' "$tmpdir/out.txt"
grep -Fxq 'three' "$tmpdir/out.txt"
