#!/usr/bin/env bash
# @testcase: usage-exif-cli-nonexistent-file-error
# @title: exif on a nonexistent path reports the not-readable diagnostic
# @description: Runs the exif client against a path that does not exist on disk and verifies the client exits with status 1, names the missing path verbatim in the diagnostic, and prints the canonical "is not readable or does not contain EXIF data" message that callers parse to distinguish IO failures from clean runs on Ubuntu 24.04.
# @timeout: 60
# @tags: usage, metadata, error
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-exif-cli-nonexistent-file-error"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

missing="$tmpdir/does-not-exist-$$.jpg"
if [[ -e "$missing" ]]; then
  printf 'precondition: missing path unexpectedly exists: %s\n' "$missing" >&2
  exit 1
fi

set +e
exif "$missing" >"$tmpdir/stdout" 2>"$tmpdir/stderr"
rc=$?
set -e

if (( rc != 1 )); then
  printf 'expected rc=1 for missing path, got %d\n' "$rc" >&2
  cat "$tmpdir/stdout" "$tmpdir/stderr" >&2
  exit 1
fi

cat "$tmpdir/stdout" "$tmpdir/stderr" >"$tmpdir/all"
validator_assert_contains "$tmpdir/all" 'is not readable or does not contain EXIF data'
validator_assert_contains "$tmpdir/all" "$missing"
