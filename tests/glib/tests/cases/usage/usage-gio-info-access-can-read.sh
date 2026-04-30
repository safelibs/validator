#!/usr/bin/env bash
# @testcase: usage-gio-info-access-can-read
# @title: gio info access can-read attribute
# @description: Reads the access::can-read attribute on a freshly created local file via gio info and verifies the attribute is reported as TRUE.
# @timeout: 120
# @tags: usage, gio
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gio-info-access-can-read"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'readable payload\n' >"$tmpdir/input.txt"
gio info -a 'access::can-read' "$tmpdir/input.txt" >"$tmpdir/out"

validator_assert_contains "$tmpdir/out" 'access::can-read:'
validator_assert_contains "$tmpdir/out" 'access::can-read: TRUE'
