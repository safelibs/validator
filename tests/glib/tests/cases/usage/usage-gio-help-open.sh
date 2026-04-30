#!/usr/bin/env bash
# @testcase: usage-gio-help-open
# @title: gio help open usage banner
# @description: Invokes gio help open and verifies the documented usage line for opening locations is reported.
# @timeout: 120
# @tags: usage, gio, help
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gio-help-open"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gio help open >"$tmpdir/out" 2>&1

validator_assert_contains "$tmpdir/out" 'Usage:'
validator_assert_contains "$tmpdir/out" 'gio open'
validator_assert_contains "$tmpdir/out" 'LOCATION'
