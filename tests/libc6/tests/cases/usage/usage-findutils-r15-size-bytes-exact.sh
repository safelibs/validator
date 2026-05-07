#!/usr/bin/env bash
# @testcase: usage-findutils-r15-size-bytes-exact
# @title: findutils find -size 100c selects only files of exactly 100 bytes
# @description: Creates three fixed-size files (50, 100, 200 bytes), runs find -size 100c -printf '%f\n' under LC_ALL=C, and asserts only the 100-byte file is reported — exercising findutils' libc-backed stat-size predicate.
# @timeout: 60
# @tags: usage, findutils, size, r15
# @client: findutils

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/d"
LC_ALL=C printf '%.0sX' {1..50}  >"$tmpdir/d/small.bin"
LC_ALL=C printf '%.0sX' {1..100} >"$tmpdir/d/exact.bin"
LC_ALL=C printf '%.0sX' {1..200} >"$tmpdir/d/large.bin"

[[ "$(wc -c <"$tmpdir/d/small.bin")" -eq 50 ]]
[[ "$(wc -c <"$tmpdir/d/exact.bin")" -eq 100 ]]
[[ "$(wc -c <"$tmpdir/d/large.bin")" -eq 200 ]]

LC_ALL=C find "$tmpdir/d" -mindepth 1 -maxdepth 1 -type f -size 100c -printf '%f\n' \
  | LC_ALL=C sort >"$tmpdir/got.txt"

got=$(cat "$tmpdir/got.txt")
[[ "$got" == "exact.bin" ]]
