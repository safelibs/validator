#!/usr/bin/env bash
# @testcase: usage-xmlstarlet-r10-sel-string-length-fn
# @title: xmlstarlet sel computes XPath string-length on element text
# @description: Selects string-length() of a known text node and asserts the printed integer equals the byte-length of the source string.
# @timeout: 60
# @tags: usage, xmlstarlet, xpath
# @client: xmlstarlet

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.xml" <<'XML'
<root>
  <name>abcdef</name>
</root>
XML

xmlstarlet sel -t -v 'string-length(/root/name)' "$tmpdir/in.xml" >"$tmpdir/out"
read -r value <"$tmpdir/out"
[[ "$value" == "6" ]] || {
  echo "expected 6, got: $value" >&2
  exit 1
}
