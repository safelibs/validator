#!/usr/bin/env bash
# @testcase: usage-gio-list-show-hidden
# @title: gio list shows hidden entries with -h
# @description: Verifies gio list -h includes dotfile entries that are omitted by default in the same directory listing.
# @timeout: 120
# @tags: usage, gio, filesystem
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gio-list-show-hidden"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'visible\n' >"$tmpdir/visible.txt"
printf 'hidden\n' >"$tmpdir/.secret"

gio list "$tmpdir" >"$tmpdir/default.out"
gio list -h "$tmpdir" >"$tmpdir/hidden.out"

validator_assert_contains "$tmpdir/default.out" 'visible.txt'
grep -Fq '.secret' "$tmpdir/default.out" && {
  printf 'unexpected hidden entry in default listing\n' >&2
  exit 1
}

validator_assert_contains "$tmpdir/hidden.out" 'visible.txt'
validator_assert_contains "$tmpdir/hidden.out" '.secret'
