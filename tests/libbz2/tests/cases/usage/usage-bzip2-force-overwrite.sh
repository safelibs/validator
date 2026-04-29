#!/usr/bin/env bash
# @testcase: usage-bzip2-force-overwrite
# @title: bzip2 force overwrite
# @description: Runs bzip2 forced recompression and verifies the replacement compressed payload is used.
# @timeout: 180
# @tags: usage, compression
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'old compressed payload\n' >"$tmpdir/payload"
bzip2 -kf "$tmpdir/payload"

printf 'new compressed payload\n' >"$tmpdir/payload"
bzip2 -kf "$tmpdir/payload"

printf 'new compressed payload\n' >"$tmpdir/expected"
bunzip2 -kc "$tmpdir/payload.bz2" >"$tmpdir/out"

cmp "$tmpdir/expected" "$tmpdir/out"
printf 'bzip2 force overwrite ok\n'
