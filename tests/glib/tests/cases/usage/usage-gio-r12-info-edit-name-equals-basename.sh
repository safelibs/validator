#!/usr/bin/env bash
# @testcase: usage-gio-r12-info-edit-name-equals-basename
# @title: gio info reports standard::edit-name matching the file basename
# @description: Creates a regular file and asserts gio info -a standard::edit-name surfaces an edit-name attribute equal to the basename component.
# @timeout: 60
# @tags: usage, gio, info, attribute
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

echo "data" >"$tmpdir/r12-edit-name.txt"
gio info -a standard::edit-name "$tmpdir/r12-edit-name.txt" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'standard::edit-name: r12-edit-name.txt'
