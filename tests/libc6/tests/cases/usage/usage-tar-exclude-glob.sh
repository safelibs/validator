#!/usr/bin/env bash
# @testcase: usage-tar-exclude-glob
# @title: tar exclude glob omits matches
# @description: Creates a tar archive with --exclude='*.log' and verifies that .log members are absent from the listing while other members remain.
# @timeout: 180
# @tags: usage, tar, archive
# @client: tar

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-tar-exclude-glob"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in"
printf 'keep payload\n' >"$tmpdir/in/data.txt"
printf 'keep config\n' >"$tmpdir/in/app.conf"
printf 'noisy log\n' >"$tmpdir/in/run.log"
printf 'noisy debug\n' >"$tmpdir/in/debug.log"

tar -cf "$tmpdir/archive.tar" -C "$tmpdir/in" --exclude='*.log' .

tar -tf "$tmpdir/archive.tar" | sort >"$tmpdir/list"

if grep -q '\.log$' "$tmpdir/list"; then
  printf 'unexpected .log member retained:\n' >&2
  cat "$tmpdir/list" >&2
  exit 1
fi

validator_assert_contains "$tmpdir/list" 'data.txt'
validator_assert_contains "$tmpdir/list" 'app.conf'

# Two regular files plus the directory entry "./".
member_count=$(grep -cv '/$' "$tmpdir/list")
if (( member_count != 2 )); then
  printf 'expected 2 non-directory members, got %s\n' "$member_count" >&2
  cat "$tmpdir/list" >&2
  exit 1
fi
