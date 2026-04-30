#!/usr/bin/env bash
# @testcase: usage-gio-rename-file
# @title: gio renames file in place
# @description: Renames a file via gio rename and verifies the new name exists while the old one is gone.
# @timeout: 120
# @tags: usage, gio, filesystem
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gio-rename-file"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'rename payload\n' >"$tmpdir/before.txt"
gio rename "$tmpdir/before.txt" 'after.txt'

validator_require_file "$tmpdir/after.txt"
if [[ -e "$tmpdir/before.txt" ]]; then
  printf 'gio rename left original path in place\n' >&2
  exit 1
fi
validator_assert_contains "$tmpdir/after.txt" 'rename payload'
