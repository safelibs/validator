#!/usr/bin/env bash
# @testcase: usage-coreutils-sort-version-batch11
# @title: coreutils version sort
# @description: Sorts version-like strings through coreutils sort -V.
# @timeout: 180
# @tags: usage, coreutils, locale
# @client: coreutils

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-coreutils-sort-version-batch11"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'v2\nv10\nv1\n' >"$tmpdir/in.txt"
sort -V "$tmpdir/in.txt" >"$tmpdir/out"
printf 'v1\nv2\nv10\n' >"$tmpdir/expected"
cmp "$tmpdir/expected" "$tmpdir/out"
