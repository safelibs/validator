#!/usr/bin/env bash
# @testcase: usage-gio-set-display-name
# @title: gio set string standard display-name reports unsupported on local fs
# @description: Attempts to set the standard::display-name attribute on a local file via gio set --type=string and verifies that the local file backend reports the documented "Setting attribute standard::display-name not supported" diagnostic without altering the file on disk.
# @timeout: 180
# @tags: usage, gio, filesystem
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gio-set-display-name"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'rename payload\n' >"$tmpdir/before.txt"

# The local file backend on Ubuntu 24.04 cannot rewrite the canonical
# standard::display-name attribute. The gio CLI exits non-zero and prints a
# "not supported" diagnostic; the file on disk must remain untouched.
set +e
gio set --type=string "$tmpdir/before.txt" standard::display-name 'after.txt' >"$tmpdir/stdout" 2>"$tmpdir/stderr"
status=$?
set -e

if [[ $status -eq 0 ]]; then
  printf 'expected gio set to fail with not-supported, got success\n' >&2
  cat "$tmpdir/stdout" "$tmpdir/stderr" >&2
  exit 1
fi

validator_assert_contains "$tmpdir/stderr" 'standard::display-name'
validator_assert_contains "$tmpdir/stderr" 'not supported'

# The original file must still exist with its original name.
validator_require_file "$tmpdir/before.txt"
test ! -e "$tmpdir/after.txt"
