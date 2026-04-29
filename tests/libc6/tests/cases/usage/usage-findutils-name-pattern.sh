#!/usr/bin/env bash
# @testcase: usage-findutils-name-pattern
# @title: findutils name pattern
# @description: Filters files by shell glob with find and verifies only matching paths are returned.
# @timeout: 180
# @tags: usage, filesystem
# @client: findutils

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-findutils-name-pattern"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/tree"
: >"$tmpdir/tree/alpha.txt"
: >"$tmpdir/tree/beta.log"
find "$tmpdir/tree" -name '*.txt' | sort >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'alpha.txt'
if grep -Fq 'beta.log' "$tmpdir/out"; then
  printf 'find unexpectedly matched beta.log\n' >&2
  exit 1
fi
