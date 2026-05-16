#!/usr/bin/env bash
# @testcase: usage-gio-r21-tree-three-level-nested-directory-shows-deepest-leaf
# @title: gio tree on a three-level nested directory shows the deepest leaf filename
# @description: Creates a three-level nested directory structure a/b/c/leaf.txt in tmpdir, runs gio tree from the top, and asserts the captured output contains the literal "leaf.txt" basename, exercising gio tree depth traversal to a three-level depth distinct from prior single-level and two-level nested tree tests.
# @timeout: 60
# @tags: usage, gio, tree, nested, r21
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/a/b/c"
printf 'deep leaf payload\n' >"$tmpdir/a/b/c/leaf.txt"

gio tree "$tmpdir" >"$tmpdir/tree.txt"
validator_assert_contains "$tmpdir/tree.txt" 'leaf.txt'
