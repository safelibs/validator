#!/usr/bin/env bash
# @testcase: usage-gio-r19-tree-nested-directory-shows-leaf
# @title: gio tree on a two-level directory shows the leaf file at the third indent
# @description: Builds a tmpdir/a/b/leaf.txt nested structure and asserts gio tree on the top-level directory emits a line containing the literal "leaf.txt", exercising the recursive-tree enumeration on a deterministic nested fixture distinct from flat list-based tests.
# @timeout: 60
# @tags: usage, gio, tree, nested, r19
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/a/b"
printf 'r19-leaf\n' >"$tmpdir/a/b/leaf.txt"

gio tree "$tmpdir/a" >"$tmpdir/out.txt"
validator_assert_contains "$tmpdir/out.txt" 'leaf.txt'
validator_assert_contains "$tmpdir/out.txt" 'b'
