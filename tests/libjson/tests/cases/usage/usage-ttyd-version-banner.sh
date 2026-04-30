#!/usr/bin/env bash
# @testcase: usage-ttyd-version-banner
# @title: ttyd version banner
# @description: Invokes ttyd --version and verifies the banner advertises a SemVer-shaped ttyd version string.
# @timeout: 60
# @tags: usage, ttyd
# @client: ttyd

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-ttyd-version-banner"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ttyd --version >"$tmpdir/version.txt" 2>&1
validator_assert_contains "$tmpdir/version.txt" 'ttyd version'

# Must report a SemVer-shaped version after the "ttyd version" prefix. The
# Ubuntu 24.04 ttyd 1.7.x build prints e.g. "ttyd version 1.7.4-..." with no
# separate libwebsockets line, so we anchor on the version number alone.
grep -Eq '^ttyd version [0-9]+\.[0-9]+\.[0-9]+' "$tmpdir/version.txt" || {
  printf 'ttyd --version banner missing SemVer suffix\n' >&2
  cat "$tmpdir/version.txt" >&2
  exit 1
}
