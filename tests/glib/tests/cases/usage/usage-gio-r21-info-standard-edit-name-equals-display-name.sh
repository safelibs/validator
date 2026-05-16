#!/usr/bin/env bash
# @testcase: usage-gio-r21-info-standard-edit-name-equals-display-name
# @title: gio info standard::edit-name and standard::display-name agree for an ASCII filename
# @description: Creates a file named "r21-edit.txt" in tmpdir and asserts gio info -a 'standard::*' emits both "standard::edit-name: r21-edit.txt" and "standard::display-name: r21-edit.txt" on separate lines, exercising the equality of edit-name and display-name for an ASCII basename distinct from prior edit-name-only or display-name-only tests.
# @timeout: 60
# @tags: usage, gio, info, edit-name, r21
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

target="$tmpdir/r21-edit.txt"
printf 'edit-name and display-name agree\n' >"$target"
gio info -a 'standard::*' "$target" >"$tmpdir/info.txt"
validator_assert_contains "$tmpdir/info.txt" 'standard::edit-name: r21-edit.txt'
validator_assert_contains "$tmpdir/info.txt" 'standard::display-name: r21-edit.txt'
