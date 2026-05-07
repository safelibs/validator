#!/usr/bin/env bash
# @testcase: usage-minisign-r15-help-mentions-verify
# @title: minisign -h help banner advertises -V verify and -S sign flags
# @description: Runs minisign -h (help) under LC_ALL=C, captures stdout+stderr, and asserts the banner output contains the literal -V (verify) and -S (sign) flag tokens — exercising minisign's libsodium-linked CLI startup and option dispatcher banner.
# @timeout: 60
# @tags: usage, minisign, help, r15
# @client: minisign

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# minisign -h prints to stderr; capture both streams.
LC_ALL=C minisign -h >"$tmpdir/out" 2>&1 || true
[[ -s "$tmpdir/out" ]]

LC_ALL=C grep -E '(^|[[:space:]])-V([[:space:]]|$)' "$tmpdir/out" >/dev/null || {
  echo 'minisign -h did not advertise -V flag' >&2
  cat "$tmpdir/out" >&2
  exit 1
}
LC_ALL=C grep -E '(^|[[:space:]])-S([[:space:]]|$)' "$tmpdir/out" >/dev/null || {
  echo 'minisign -h did not advertise -S flag' >&2
  cat "$tmpdir/out" >&2
  exit 1
}
