#!/usr/bin/env bash
# @testcase: usage-xmlstarlet-r9-ed-update-value
# @title: xmlstarlet ed updates element text
# @description: Uses xmlstarlet ed -u to replace a text node selected by XPath and verifies the new value appears in the output while the old value is gone.
# @timeout: 60
# @tags: usage, xmlstarlet, edit
# @client: xmlstarlet

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.xml" <<'XML'
<root>
  <name>old</name>
  <age>30</age>
</root>
XML

xmlstarlet ed -u '/root/name' -v 'new' "$tmpdir/in.xml" >"$tmpdir/out.xml"
validator_assert_contains "$tmpdir/out.xml" '<name>new</name>'
if grep -q '<name>old</name>' "$tmpdir/out.xml"; then
  echo 'old value not replaced' >&2
  cat "$tmpdir/out.xml" >&2
  exit 1
fi

# Original file untouched (xmlstarlet ed prints to stdout without -L).
grep -q '<name>old</name>' "$tmpdir/in.xml"
