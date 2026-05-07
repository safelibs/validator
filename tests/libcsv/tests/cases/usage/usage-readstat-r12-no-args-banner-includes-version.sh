#!/usr/bin/env bash
# @testcase: usage-readstat-r12-no-args-banner-includes-version
# @title: readstat with no arguments prints the usage banner including ReadStat version
# @description: Invokes readstat with no arguments, captures stdout+stderr, and asserts the resulting banner contains both the "ReadStat version" line and the conversion-mode descriptions, ensuring the bare-invocation path matches the help-flag content shape.
# @timeout: 60
# @tags: usage, csv, cli, banner
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

readstat >"$tmpdir/stdout" 2>"$tmpdir/stderr" || true
cat "$tmpdir/stdout" "$tmpdir/stderr" >"$tmpdir/all"

validator_assert_contains "$tmpdir/all" 'ReadStat version'
validator_assert_contains "$tmpdir/all" 'Convert a file'
# At least one shape we can pin: the version line must match the X.Y.Z form.
grep -E 'ReadStat version [0-9]+\.[0-9]+\.[0-9]+' "$tmpdir/all" >/dev/null || {
  printf 'banner missing X.Y.Z version line\n' >&2
  cat "$tmpdir/all" >&2
  exit 1
}
