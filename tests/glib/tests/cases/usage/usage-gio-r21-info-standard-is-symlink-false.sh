#!/usr/bin/env bash
# @testcase: usage-gio-r21-info-standard-is-symlink-false
# @title: gio info -a standard::is-symlink reports FALSE for a regular file
# @description: Creates a regular file in tmpdir and asserts gio info -a standard::is-symlink emits the line "standard::is-symlink: FALSE", exercising the standard::is-symlink boolean attribute on a non-symlink target distinct from prior symlink-target attribute tests.
# @timeout: 60
# @tags: usage, gio, info, is-symlink, r21
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'r21 is-symlink false\n' >"$tmpdir/regular.txt"
gio info -a standard::is-symlink "$tmpdir/regular.txt" >"$tmpdir/info.txt"
validator_assert_contains "$tmpdir/info.txt" 'standard::is-symlink: FALSE'
