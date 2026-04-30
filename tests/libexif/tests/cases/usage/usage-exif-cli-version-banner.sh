#!/usr/bin/env bash
# @testcase: usage-exif-cli-version-banner
# @title: exif --version reports a parseable banner
# @description: Runs the exif client with --version and verifies the banner is a single line containing a numeric major.minor.patch version starting with 0.6, matching the libexif Ubuntu 24.04 baseline 0.6.x series.
# @timeout: 60
# @tags: usage, metadata
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-exif-cli-version-banner"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

exif --version >"$tmpdir/out" 2>&1

# Single non-empty line
line_count=$(wc -l <"$tmpdir/out")
if (( line_count != 1 )); then
  printf 'expected 1 line of --version output, got %s\n' "$line_count" >&2
  cat "$tmpdir/out" >&2
  exit 1
fi

# Numeric major.minor.patch starting with 0.6
if ! grep -Eq '^0\.6\.[0-9]+$' "$tmpdir/out"; then
  printf 'unexpected --version banner content\n' >&2
  cat "$tmpdir/out" >&2
  exit 1
fi
