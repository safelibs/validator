#!/usr/bin/env bash
# @testcase: usage-bzip2-decompress-missing-file-exit
# @title: bzip2 -d missing file fails
# @description: Asks bzip2 -d to decompress a path that does not exist and confirms it exits non-zero with an error written to stderr.
# @timeout: 60
# @tags: usage, bzip2, negative
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bzip2-decompress-missing-file-exit"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

target="$tmpdir/does-not-exist.bz2"
[[ ! -e "$target" ]]

if bzip2 -d "$target" >"$tmpdir/out" 2>"$tmpdir/err"; then
  printf 'bzip2 -d unexpectedly succeeded on a missing path\n' >&2
  exit 1
fi
test -s "$tmpdir/err"
grep -qiE "no such file|can't open|cannot|not found" "$tmpdir/err" || {
  printf 'unexpected stderr for missing input:\n' >&2
  cat "$tmpdir/err" >&2
  exit 1
}
