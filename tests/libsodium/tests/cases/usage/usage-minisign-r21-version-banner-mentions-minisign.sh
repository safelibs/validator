#!/usr/bin/env bash
# @testcase: usage-minisign-r21-version-banner-mentions-minisign
# @title: minisign -v prints a banner containing the word minisign
# @description: Invokes minisign -v, captures stdout/stderr, and asserts the combined output contains the literal string "minisign", confirming the libsodium-backed CLI announces its identity on the version flag.
# @timeout: 30
# @tags: usage, sodium, minisign, version, r21
# @client: minisign

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

minisign -v >"$tmpdir/out.txt" 2>&1 || true
grep -qi 'minisign' "$tmpdir/out.txt" || {
  echo 'banner did not mention minisign:' >&2
  cat "$tmpdir/out.txt" >&2
  exit 1
}
echo "ok minisign version banner"
