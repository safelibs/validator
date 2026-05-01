#!/usr/bin/env bash
# @testcase: usage-gio-list-attribute-projection
# @title: gio list -a projects requested attribute
# @description: Asks gio list for the unix::inode attribute and verifies the projected listing reports a non-zero inode for the seeded file.
# @timeout: 120
# @tags: usage, gio, attributes
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gio-list-attribute-projection"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'inode probe\n' >"$tmpdir/probe.txt"
gio list -a unix::inode "$tmpdir" >"$tmpdir/out"

# Output format is "<name>\t<size>\t(<type>)\tunix::inode=<n>"
validator_assert_contains "$tmpdir/out" 'probe.txt'
validator_assert_contains "$tmpdir/out" 'unix::inode='
grep -E 'probe\.txt.*unix::inode=[1-9][0-9]*' "$tmpdir/out" >/dev/null
