#!/usr/bin/env bash
# @testcase: usage-bzip2-v-flag-version-line-format
# @title: bzip2 -V emits a strictly formatted "Version X.Y.Z, dd-Mon-yyyy" line
# @description: Runs bzip2 -V, captures the banner from stdout+stderr (the upstream banner historically goes to stderr with exit 1), and verifies a single canonical "Version X.Y.Z, dd-Mon-yyyy" line is present alongside the program name, "block-sorting" wording, copyright, and the Julian Seward attribution.
# @timeout: 180
# @tags: usage, bzip2, version, banner
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Tolerate exit 0 or 1 (upstream banner is emitted on stderr with rc=1).
set +e
bzip2 -V >"$tmpdir/out" 2>"$tmpdir/err"
rc=$?
set -e
[[ "$rc" -eq 0 || "$rc" -eq 1 ]] || {
  printf 'unexpected bzip2 -V exit code: %s\n' "$rc" >&2
  exit 1
}

cat "$tmpdir/out" "$tmpdir/err" >"$tmpdir/banner"
[[ -s "$tmpdir/banner" ]] || {
  printf 'bzip2 -V produced no banner\n' >&2
  exit 1
}

# Required textual hooks.
validator_assert_contains "$tmpdir/banner" 'bzip2, a block-sorting file compressor.'
validator_assert_contains "$tmpdir/banner" 'Copyright'
validator_assert_contains "$tmpdir/banner" 'Julian Seward'

# Strict format: exactly one "Version X.Y.Z, dd-Mon-yyyy." line.
version_line=$(grep -Eo \
  'Version [0-9]+\.[0-9]+\.[0-9]+, [0-9]{1,2}-(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)-[0-9]{4}' \
  "$tmpdir/banner" | head -n1 || true)

if [[ -z "$version_line" ]]; then
  printf 'banner missing "Version X.Y.Z, dd-Mon-yyyy" line:\n' >&2
  cat "$tmpdir/banner" >&2
  exit 1
fi

# Confirm there is exactly one such line in the banner (no duplicates / drift).
match_count=$(grep -Ec \
  'Version [0-9]+\.[0-9]+\.[0-9]+, [0-9]{1,2}-(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)-[0-9]{4}' \
  "$tmpdir/banner")
[[ "$match_count" -eq 1 ]] || {
  printf 'expected exactly one Version line, found %s:\n' "$match_count" >&2
  cat "$tmpdir/banner" >&2
  exit 1
}

# Extract the bare version triple for the matrix log.
version=$(printf '%s\n' "$version_line" | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+')
[[ -n "$version" ]]
echo "parsed bzip2 -V line: $version_line" >&2
echo "parsed bzip2 version triple: $version" >&2
