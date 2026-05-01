#!/usr/bin/env bash
# @testcase: usage-gio-info-query-writable-namespaces
# @title: gio info -w lists writable namespaces
# @description: Runs gio info --query-writable on a regular file and verifies the output enumerates settable attributes such as time::modified and the xattr namespace.
# @timeout: 120
# @tags: usage, gio, attributes
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gio-info-query-writable-namespaces"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'writable probe\n' >"$tmpdir/file.txt"
gio info -w "$tmpdir/file.txt" >"$tmpdir/out"

validator_assert_contains "$tmpdir/out" 'Settable attributes:'
validator_assert_contains "$tmpdir/out" 'time::modified'
validator_assert_contains "$tmpdir/out" 'unix::mode'
validator_assert_contains "$tmpdir/out" 'Writable attribute namespaces:'
validator_assert_contains "$tmpdir/out" 'xattr'
