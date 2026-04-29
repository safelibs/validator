#!/usr/bin/env bash
# @testcase: usage-findutils-empty-files
# @title: findutils empty file filter
# @description: Exercises findutils empty file filter through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: findutils

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-findutils-empty-files"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/root"
: >"$tmpdir/root/empty.txt"
printf 'non-empty\n' >"$tmpdir/root/full.txt"
find "$tmpdir/root" -type f -empty >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'empty.txt'
if grep -Fq 'full.txt' "$tmpdir/out"; then exit 1; fi
