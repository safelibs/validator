#!/usr/bin/env bash
# @testcase: usage-gio-info-query-writable
# @title: gio info --query-writable lists writable namespaces
# @description: Runs gio info --query-writable on a local file and verifies common writable namespaces are reported.
# @timeout: 180
# @tags: usage, gio, metadata
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gio-info-query-writable"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'writable payload\n' >"$tmpdir/input.txt"
gio info --query-writable "$tmpdir/input.txt" >"$tmpdir/out"

# The local file backend exposes at least the unix and time namespaces as
# writable. Verify both show up so we know the writable enumeration ran.
validator_assert_contains "$tmpdir/out" 'unix::'
validator_assert_contains "$tmpdir/out" 'time::'
