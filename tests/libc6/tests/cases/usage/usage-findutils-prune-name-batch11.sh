#!/usr/bin/env bash
# @testcase: usage-findutils-prune-name-batch11
# @title: find prune name
# @description: Traverses a tree with find while pruning a named directory.
# @timeout: 180
# @tags: usage, find, filesystem
# @client: findutils

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-findutils-prune-name-batch11"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/tree/keep" "$tmpdir/tree/skip"
: >"$tmpdir/tree/keep/seen.txt"
: >"$tmpdir/tree/skip/hidden.txt"
find "$tmpdir/tree" -name skip -prune -o -type f -printf '%f\n' >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'seen.txt'
if grep -Fq 'hidden.txt' "$tmpdir/out"; then exit 1; fi
