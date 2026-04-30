#!/usr/bin/env bash
# @testcase: usage-gio-version-banner
# @title: gio version prints GLib version
# @description: Invokes gio version and verifies it prints a numeric GLib release banner.
# @timeout: 60
# @tags: usage, gio
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gio-version-banner"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gio version >"$tmpdir/out"
grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+' "$tmpdir/out" || {
  printf 'gio version did not print a version number\n' >&2
  cat "$tmpdir/out" >&2
  exit 1
}
