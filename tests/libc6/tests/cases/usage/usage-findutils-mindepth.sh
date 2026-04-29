#!/usr/bin/env bash
# @testcase: usage-findutils-mindepth
# @title: findutils mindepth filter
# @description: Filters nested files with find -mindepth and verifies only deeper matches are returned.
# @timeout: 180
# @tags: usage, findutils, filesystem
# @client: findutils

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-findutils-mindepth"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/tree/sub"
: >"$tmpdir/tree/root.txt"
: >"$tmpdir/tree/sub/leaf.txt"
find "$tmpdir/tree" -mindepth 2 -type f | sort >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'leaf.txt'
if grep -Fq 'root.txt' "$tmpdir/out"; then
  printf 'mindepth output unexpectedly included root.txt\n' >&2
  exit 1
fi
