#!/usr/bin/env bash
# @testcase: usage-gio-info-attribute-namespace-etag
# @title: gio info etag attribute namespace
# @description: Queries the etag::value attribute via gio info -a and verifies the attribute label appears next to a populated value.
# @timeout: 120
# @tags: usage, gio, attributes
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gio-info-attribute-namespace-etag"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'etag namespace payload\n' >"$tmpdir/file.txt"
gio info -a etag::value "$tmpdir/file.txt" >"$tmpdir/out"

validator_assert_contains "$tmpdir/out" 'etag::value:'
validator_assert_contains "$tmpdir/out" 'attributes:'
