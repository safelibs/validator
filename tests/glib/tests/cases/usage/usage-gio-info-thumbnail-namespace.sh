#!/usr/bin/env bash
# @testcase: usage-gio-info-thumbnail-namespace
# @title: gio info thumbnail namespace
# @description: Queries the thumbnail::path attribute via gio info on a non-thumbnailable local file and verifies the command succeeds with the expected info banner even when no thumbnail attribute is materialized.
# @timeout: 120
# @tags: usage, gio
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gio-info-thumbnail-namespace"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'thumbnail probe payload\n' >"$tmpdir/input.txt"
gio info -a 'thumbnail::path' "$tmpdir/input.txt" >"$tmpdir/out"

validator_assert_contains "$tmpdir/out" 'uri: file://'
validator_assert_contains "$tmpdir/out" 'input.txt'
validator_assert_contains "$tmpdir/out" 'attributes:'
