#!/usr/bin/env bash
# @testcase: usage-gio-info-size-batch11
# @title: gio info standard size
# @description: Reads the standard size attribute for a local file through gio.
# @timeout: 180
# @tags: usage, gio, filesystem
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gio-info-size-batch11"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf '12345' >"$tmpdir/sized.txt"
gio info -a standard::size "$tmpdir/sized.txt" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'standard::size: 5'
