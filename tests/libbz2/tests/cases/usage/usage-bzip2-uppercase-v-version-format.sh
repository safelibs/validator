#!/usr/bin/env bash
# @testcase: usage-bzip2-uppercase-v-version-format
# @title: bzip2 -V emits the canonical version banner format
# @description: Runs bzip2 -V and verifies the emitted banner matches the canonical "bzip2, a block-sorting file compressor.  Version <X.Y.Z>" format, exposing copyright attribution and the parseable version triple.
# @timeout: 180
# @tags: usage, bzip2, version
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# bzip2 -V exits non-zero (status 1) but writes its banner to stderr.
# Capture both streams and tolerate the documented exit code.
set +e
bzip2 -V >"$tmpdir/out" 2>"$tmpdir/err"
rc=$?
set -e
# Accept exit 0 or 1 (the upstream banner historically returns 1 alongside
# the help text on stderr).
[[ "$rc" -eq 0 || "$rc" -eq 1 ]] || {
  printf 'unexpected bzip2 -V exit code: %s\n' "$rc" >&2
  exit 1
}

# Combine both streams: the banner is emitted to stderr.
cat "$tmpdir/out" "$tmpdir/err" >"$tmpdir/banner"
[[ -s "$tmpdir/banner" ]] || {
  printf 'expected bzip2 -V to print a banner\n' >&2
  exit 1
}

# Required banner phrases.
validator_assert_contains "$tmpdir/banner" 'bzip2, a block-sorting file compressor.'
validator_assert_contains "$tmpdir/banner" 'Version'
validator_assert_contains "$tmpdir/banner" 'Copyright'
validator_assert_contains "$tmpdir/banner" 'Julian Seward'

# Strict regex check: a "Version X.Y.Z" or "Version X.Y.Z, <date>" line.
grep -Eq 'Version [0-9]+\.[0-9]+\.[0-9]+' "$tmpdir/banner" || {
  printf 'banner missing parseable Version X.Y.Z token:\n' >&2
  cat "$tmpdir/banner" >&2
  exit 1
}

# Extract and echo the parsed version for the matrix log.
version=$(grep -Eo 'Version [0-9]+\.[0-9]+\.[0-9]+' "$tmpdir/banner" | head -n1 | awk '{print $2}')
echo "parsed bzip2 version: $version" >&2
[[ -n "$version" ]]
