#!/usr/bin/env bash
# @testcase: usage-gio-rename-tmp-suffix
# @title: gio rename swaps tmp suffix
# @description: Renames a file from old.tmp to new.tmp via gio rename and verifies the new name exists with the original payload while the old path is gone.
# @timeout: 120
# @tags: usage, gio, filesystem
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gio-rename-tmp-suffix"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'tmp suffix payload\n' >"$tmpdir/old.tmp"
gio rename "$tmpdir/old.tmp" 'new.tmp'

validator_require_file "$tmpdir/new.tmp"
if [[ -e "$tmpdir/old.tmp" ]]; then
  printf 'gio rename left old.tmp in place\n' >&2
  exit 1
fi
validator_assert_contains "$tmpdir/new.tmp" 'tmp suffix payload'
