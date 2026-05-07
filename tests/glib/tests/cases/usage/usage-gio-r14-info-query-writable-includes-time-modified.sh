#!/usr/bin/env bash
# @testcase: usage-gio-r14-info-query-writable-includes-time-modified
# @title: gio info -w on a directory enumerates standard settable attributes
# @description: Calls gio info --query-writable on a freshly-created directory and asserts the settable attributes section includes time::modified and unix::mode while the writable namespaces section includes the xattr namespace.
# @timeout: 60
# @tags: usage, gio, attributes, writable
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir "$tmpdir/probe-dir"
gio info -w "$tmpdir/probe-dir" >"$tmpdir/out"

validator_assert_contains "$tmpdir/out" 'Settable attributes:'
validator_assert_contains "$tmpdir/out" 'time::modified'
validator_assert_contains "$tmpdir/out" 'unix::mode'
validator_assert_contains "$tmpdir/out" 'Writable attribute namespaces:'
validator_assert_contains "$tmpdir/out" 'xattr'
