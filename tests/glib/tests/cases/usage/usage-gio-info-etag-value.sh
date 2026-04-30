#!/usr/bin/env bash
# @testcase: usage-gio-info-etag-value
# @title: gio info reports etag::value attribute
# @description: Queries the etag::value file attribute through gio info -a and verifies the attribute label appears with a non-empty value.
# @timeout: 120
# @tags: usage, gio, attributes
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gio-info-etag-value"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'etag payload\n' >"$tmpdir/file.txt"
gio info -a etag::value "$tmpdir/file.txt" >"$tmpdir/out"

validator_assert_contains "$tmpdir/out" 'etag::value:'
validator_assert_contains "$tmpdir/out" 'file.txt'

# The attribute should have a non-empty value after the colon.
value=$(grep -E '^[[:space:]]*etag::value:' "$tmpdir/out" | head -1 | sed -E 's/^[[:space:]]*etag::value:[[:space:]]*//')
if [[ -z "$value" ]]; then
  printf 'expected non-empty etag::value, got blank\n' >&2
  sed -n '1,40p' "$tmpdir/out" >&2
  exit 1
fi
