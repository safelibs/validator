#!/usr/bin/env bash
# @testcase: usage-bzcmp-ignore-initial-bytes
# @title: bzcmp ignore initial bytes
# @description: Builds two compressed payloads that differ only in their first two decompressed bytes and verifies bzcmp --ignore-initial=2 reports them as equal while the unskipped compare exits non-zero.
# @timeout: 180
# @tags: usage, bzip2, compare
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bzcmp-ignore-initial-bytes"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'XXshared bzcmp tail\n' >"$tmpdir/a.txt"
printf 'YYshared bzcmp tail\n' >"$tmpdir/b.txt"

bzip2 -c "$tmpdir/a.txt" >"$tmpdir/a.bz2"
bzip2 -c "$tmpdir/b.txt" >"$tmpdir/b.bz2"

# Without skip the payloads differ -> bzcmp must exit non-zero.
set +e
bzcmp "$tmpdir/a.bz2" "$tmpdir/b.bz2" >"$tmpdir/diff.out" 2>&1
rc=$?
set -e
if (( rc == 0 )); then
  printf 'bzcmp unexpectedly reported equality without skip\n' >&2
  exit 1
fi
validator_assert_contains "$tmpdir/diff.out" 'differ'

# With ignore-initial=2 the remaining tails match -> bzcmp must exit 0 silently.
bzcmp --ignore-initial=2 "$tmpdir/a.bz2" "$tmpdir/b.bz2" >"$tmpdir/skip.out" 2>&1
[[ ! -s "$tmpdir/skip.out" ]]
