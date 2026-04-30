#!/usr/bin/env bash
# @testcase: usage-gio-list-uri-hidden-flag
# @title: gio list URI surfaces hidden children with --hidden
# @description: Lists a directory through a file:// URI with gio list --hidden and verifies that visible and dot-prefixed entries are both reported.
# @timeout: 180
# @tags: usage, gio, filesystem
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gio-list-uri-hidden-flag"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/tree"
printf 'visible payload\n' >"$tmpdir/tree/visible.txt"
printf 'hidden payload\n' >"$tmpdir/tree/.hidden.txt"

uri="file://$tmpdir/tree"

# Without --hidden the dotfile must not appear.
gio list "$uri" >"$tmpdir/plain"
validator_assert_contains "$tmpdir/plain" 'visible.txt'
if grep -Fq '.hidden.txt' "$tmpdir/plain"; then
  printf 'unexpected hidden entry in plain listing\n' >&2
  exit 1
fi

# With --hidden the dotfile must show up alongside the visible entry.
gio list --hidden "$uri" >"$tmpdir/all"
validator_assert_contains "$tmpdir/all" 'visible.txt'
validator_assert_contains "$tmpdir/all" '.hidden.txt'
