#!/usr/bin/env bash
# @testcase: usage-exif-cli-directory-target-error
# @title: exif on a directory target fails with the not-readable diagnostic
# @description: Invokes the exif client against a directory path (not a regular file) and verifies the client exits non-zero with the canonical "is not readable or does not contain EXIF data" diagnostic naming the directory, matching libexif's read-as-file behavior on Ubuntu 24.04.
# @timeout: 60
# @tags: usage, metadata, error
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-exif-cli-directory-target-error"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

dir_target="$tmpdir/some-dir"
mkdir -p "$dir_target"
validator_require_dir "$dir_target"

set +e
exif "$dir_target" >"$tmpdir/stdout" 2>"$tmpdir/stderr"
rc=$?
set -e

if (( rc == 0 )); then
  printf 'expected non-zero exit on directory target, got rc=0\n' >&2
  cat "$tmpdir/stdout" "$tmpdir/stderr" >&2
  exit 1
fi

cat "$tmpdir/stdout" "$tmpdir/stderr" >"$tmpdir/all"
validator_assert_contains "$tmpdir/all" 'is not readable or does not contain EXIF data'
validator_assert_contains "$tmpdir/all" "$dir_target"
