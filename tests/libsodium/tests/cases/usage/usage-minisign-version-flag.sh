#!/usr/bin/env bash
# @testcase: usage-minisign-version-flag
# @title: minisign -v reports a version banner
# @description: Invokes "minisign -v" and asserts the output begins with the documented "minisign" banner and contains a version-like dotted token, confirming the libsodium-linked minisign binary advertises its version on the help/usage path.
# @timeout: 60
# @tags: usage, minisign, version
# @client: minisign

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# minisign -v prints a banner to stderr and exits non-zero (it is not a
# subcommand on its own, it just emits version info). Capture both streams
# and tolerate a non-zero exit.
minisign -v >"$tmpdir/out" 2>"$tmpdir/err" || true

cat "$tmpdir/out" "$tmpdir/err" >"$tmpdir/combined"
validator_require_file "$tmpdir/combined"

if ! grep -qi 'minisign' "$tmpdir/combined"; then
  echo "no minisign banner in output" >&2
  cat "$tmpdir/combined" >&2
  exit 1
fi

if ! grep -Eq '[0-9]+\.[0-9]+' "$tmpdir/combined"; then
  echo "no dotted version-like token in output" >&2
  cat "$tmpdir/combined" >&2
  exit 1
fi

echo "ok"
