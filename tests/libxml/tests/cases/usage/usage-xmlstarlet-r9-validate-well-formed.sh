#!/usr/bin/env bash
# @testcase: usage-xmlstarlet-r9-validate-well-formed
# @title: xmlstarlet val accepts well-formed and rejects broken XML
# @description: Runs xmlstarlet val on a well-formed document expecting exit 0, then on a malformed document expecting non-zero exit and an error message.
# @timeout: 60
# @tags: usage, xmlstarlet, validate
# @client: xmlstarlet

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/good.xml" <<'XML'
<root><a/><b/></root>
XML

cat >"$tmpdir/bad.xml" <<'XML'
<root><a></b></root>
XML

xmlstarlet val "$tmpdir/good.xml" >"$tmpdir/good.out"
validator_assert_contains "$tmpdir/good.out" 'valid'

# Malformed input must fail.
if xmlstarlet val "$tmpdir/bad.xml" >"$tmpdir/bad.out" 2>&1; then
  echo "expected validation failure" >&2
  exit 1
fi
grep -q 'invalid' "$tmpdir/bad.out" || grep -q 'Mismatch' "$tmpdir/bad.out" || {
  cat "$tmpdir/bad.out" >&2
  exit 1
}
