#!/usr/bin/env bash
# @testcase: usage-gio-r12-mkdir-and-list-shows-entry
# @title: gio mkdir creates directory visible to gio list
# @description: Creates a subdirectory with gio mkdir under a fresh parent, then runs gio list on the parent and asserts the new entry appears in the listing.
# @timeout: 60
# @tags: usage, gio, mkdir, list
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir "$tmpdir/parent"
gio mkdir "$tmpdir/parent/r12-child"

[[ -d "$tmpdir/parent/r12-child" ]]

gio list "$tmpdir/parent" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'r12-child'
