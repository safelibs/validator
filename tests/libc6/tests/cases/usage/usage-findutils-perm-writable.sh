#!/usr/bin/env bash
# @testcase: usage-findutils-perm-writable
# @title: findutils perm any-writable filter
# @description: Uses find -perm /222 to select files with any writable bit and verifies that only the writable fixture is reported.
# @timeout: 180
# @tags: usage, findutils, filesystem
# @client: findutils

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-findutils-perm-writable"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/tree"
: >"$tmpdir/tree/writable.txt"
: >"$tmpdir/tree/readonly.txt"
chmod 0644 "$tmpdir/tree/writable.txt"
chmod 0444 "$tmpdir/tree/readonly.txt"

find "$tmpdir/tree" -type f -perm /222 -printf '%f\n' | sort >"$tmpdir/out"

validator_assert_contains "$tmpdir/out" 'writable.txt'
if grep -q '^readonly.txt$' "$tmpdir/out"; then
  printf 'readonly.txt unexpectedly matched -perm /222\n' >&2
  exit 1
fi
