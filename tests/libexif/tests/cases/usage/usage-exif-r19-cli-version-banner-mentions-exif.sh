#!/usr/bin/env bash
# @testcase: usage-exif-r19-cli-version-banner-mentions-exif
# @title: exif --version banner reports a dotted numeric version string
# @description: Runs exif --version and asserts the first non-empty stdout line matches a dotted numeric version pattern (libexif's exif CLI prints e.g. "0.6.22" as its sole banner line on noble), exercising the libexif/exif CLI version reporting path.
# @timeout: 30
# @tags: usage, exif, version, banner, r19
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

exif --version >"$tmpdir/out" 2>"$tmpdir/err"
first=$(LC_ALL=C grep -m1 -v '^[[:space:]]*$' "$tmpdir/out" || true)
if ! LC_ALL=C printf '%s\n' "$first" | grep -Eq '^[[:space:]]*[0-9]+\.[0-9]+\.[0-9]+'; then
  printf 'expected dotted numeric version, got: %s\n' "$first" >&2
  cat "$tmpdir/out" >&2
  exit 1
fi
