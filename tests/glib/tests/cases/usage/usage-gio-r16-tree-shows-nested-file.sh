#!/usr/bin/env bash
# @testcase: usage-gio-r16-tree-shows-nested-file
# @title: gio tree against a fresh directory enumerates a nested file path
# @description: Creates a fresh directory containing dir/sub/r16-leaf.txt, runs gio tree on the top directory, and asserts the output contains the nested basename "r16-leaf.txt", exercising the recursive enumeration walker.
# @timeout: 60
# @tags: usage, gio, tree
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/dir/sub"
printf 'r16-tree\n' >"$tmpdir/dir/sub/r16-leaf.txt"

gio tree "$tmpdir/dir" >"$tmpdir/out.txt"
validator_assert_contains "$tmpdir/out.txt" 'r16-leaf.txt'
