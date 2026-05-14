#!/usr/bin/env bash
# @testcase: usage-exif-r18-cli-missing-file-nonzero-exit
# @title: exif on a missing file exits non-zero
# @description: Invokes the exif CLI against a path that definitely does not exist inside the temporary directory and asserts the exit code is non-zero, exercising the error-path return from the exif client when libexif cannot open the input file (no specific stderr keyword asserted, only the failure indicator).
# @timeout: 30
# @tags: usage, exif, error, missing-file, r18
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

missing="$tmpdir/does-not-exist.jpg"
set +e
exif "$missing" >"$tmpdir/out" 2>"$tmpdir/err"
rc=$?
set -e

if [[ "$rc" -eq 0 ]]; then
  echo 'expected non-zero exit for missing file, got 0' >&2
  cat "$tmpdir/out" >&2
  cat "$tmpdir/err" >&2
  exit 1
fi
