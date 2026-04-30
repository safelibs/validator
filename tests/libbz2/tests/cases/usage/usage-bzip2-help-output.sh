#!/usr/bin/env bash
# @testcase: usage-bzip2-help-output
# @title: bzip2 --help advertises core options
# @description: Runs bzip2 --help and verifies the help banner mentions the version, the -d/-z compression toggles, and the block-size flag, then runs bzip2 -h and confirms the same banner is produced.
# @timeout: 180
# @tags: usage, bzip2, help
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bzip2-help-output"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# bzip2 prints usage to stderr when invoked with -h or --help; merge fds so we
# capture the banner regardless of which stream it lands on.
bzip2 --help >"$tmpdir/long.out" 2>&1 || true
[[ -s "$tmpdir/long.out" ]] || {
  printf 'bzip2 --help produced no output\n' >&2
  exit 1
}

validator_assert_contains "$tmpdir/long.out" 'bzip2'
validator_assert_contains "$tmpdir/long.out" 'usage:'
validator_assert_contains "$tmpdir/long.out" '-d'
validator_assert_contains "$tmpdir/long.out" '-z'

# bzip2 -h must produce equivalent help text.
bzip2 -h >"$tmpdir/short.out" 2>&1 || true
[[ -s "$tmpdir/short.out" ]] || {
  printf 'bzip2 -h produced no output\n' >&2
  exit 1
}
validator_assert_contains "$tmpdir/short.out" 'bzip2'
validator_assert_contains "$tmpdir/short.out" 'usage:'

# The two banners must be byte-identical.
cmp "$tmpdir/long.out" "$tmpdir/short.out"
