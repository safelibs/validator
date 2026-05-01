#!/usr/bin/env bash
# @testcase: usage-bzip2-stdin-no-output-file-on-error
# @title: bzip2 -d rejects non-bzip2 stdin
# @description: Pipes plain text into bzip2 -d and verifies the command exits non-zero, reports a not-a-bzip2-file error, and produces no decoded output bytes on stdout.
# @timeout: 60
# @tags: usage, bzip2, negative
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bzip2-stdin-no-output-file-on-error"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'this is plain text not a bzip2 stream\n' >"$tmpdir/plain.txt"

set +e
bzip2 -dc <"$tmpdir/plain.txt" >"$tmpdir/out" 2>"$tmpdir/err"
status=$?
set -e

[[ $status -ne 0 ]] || {
  printf 'bzip2 -dc unexpectedly succeeded on plain text input\n' >&2
  exit 1
}
test -s "$tmpdir/err"
grep -qiE 'not a bzip2 file|magic number|integrity' "$tmpdir/err" || {
  printf 'unexpected stderr:\n' >&2
  cat "$tmpdir/err" >&2
  exit 1
}
[[ ! -s "$tmpdir/out" ]] || {
  printf 'expected empty stdout on error, got %d bytes\n' "$(wc -c <"$tmpdir/out")" >&2
  exit 1
}
