#!/usr/bin/env bash
# @testcase: usage-findutils-type-filter
# @title: findutils type filtering
# @description: Filters directory entries by type with find and checks only regular files are returned.
# @timeout: 180
# @tags: usage, filesystem
# @client: findutils

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-findutils-type-filter"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/root/dir"
printf 'file\n' >"$tmpdir/root/file.txt"
find "$tmpdir/root" -type f -printf '%f\n' >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'file.txt'
if grep -Fq 'dir' "$tmpdir/out"; then exit 1; fi
