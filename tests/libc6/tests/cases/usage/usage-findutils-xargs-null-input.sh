#!/usr/bin/env bash
# @testcase: usage-findutils-xargs-null-input
# @title: findutils xargs -0 null-delimited input
# @description: Pipes find -print0 through xargs -0 to safely handle filenames with spaces and verifies all entries are processed.
# @timeout: 180
# @tags: usage, findutils
# @client: findutils

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-findutils-xargs-null-input"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/tree"
: >"$tmpdir/tree/plain.txt"
: >"$tmpdir/tree/with space.txt"
: >"$tmpdir/tree/with'quote.txt"

find "$tmpdir/tree" -maxdepth 1 -type f -name '*.txt' -print0 \
  | xargs -0 -I{} basename {} \
  | sort >"$tmpdir/out"

count=$(wc -l <"$tmpdir/out")
test "$count" -eq 3

validator_assert_contains "$tmpdir/out" 'plain.txt'
validator_assert_contains "$tmpdir/out" 'with space.txt'
validator_assert_contains "$tmpdir/out" "with'quote.txt"
