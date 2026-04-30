#!/usr/bin/env bash
# @testcase: usage-gio-info-recent-namespace
# @title: gio info recent namespace
# @description: Queries the recent::* attribute namespace through gio info on a local fixture and verifies the command succeeds with the expected URI banner.
# @timeout: 120
# @tags: usage, gio
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gio-info-recent-namespace"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'recent namespace payload\n' >"$tmpdir/input.txt"
gio info -a 'recent::*' "$tmpdir/input.txt" >"$tmpdir/out"

validator_assert_contains "$tmpdir/out" 'uri: file://'
validator_assert_contains "$tmpdir/out" 'input.txt'
validator_assert_contains "$tmpdir/out" 'attributes:'
