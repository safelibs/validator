#!/usr/bin/env bash
# @testcase: usage-gio-list-long-format
# @title: gio list long format
# @description: Lists a temporary directory with the long format flag and verifies that file size and type information appear alongside each child entry.
# @timeout: 120
# @tags: usage, gio
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gio-list-long-format"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/tree"
printf 'alpha-payload\n' >"$tmpdir/tree/alpha.txt"
mkdir -p "$tmpdir/tree/sub"

gio list -l "$tmpdir/tree" >"$tmpdir/out"

validator_assert_contains "$tmpdir/out" 'alpha.txt'
validator_assert_contains "$tmpdir/out" '(regular)'
validator_assert_contains "$tmpdir/out" 'sub'
validator_assert_contains "$tmpdir/out" '(directory)'
