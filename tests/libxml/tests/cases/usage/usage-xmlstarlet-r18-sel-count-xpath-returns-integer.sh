#!/usr/bin/env bash
# @testcase: usage-xmlstarlet-r18-sel-count-xpath-returns-integer
# @title: xmlstarlet sel -t -v with count XPath returns the element count as an integer
# @description: Builds a small XML document with five <leaf> children, queries it via xmlstarlet sel -t -v 'count(//leaf)', and asserts the printed value is exactly 5 to pin the XPath count() integer-string emission.
# @timeout: 60
# @tags: usage, xmlstarlet, sel, xpath, r18
# @client: xmlstarlet

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.xml" <<'XML'
<?xml version="1.0"?>
<r>
  <leaf>a</leaf>
  <leaf>b</leaf>
  <leaf>c</leaf>
  <leaf>d</leaf>
  <leaf>e</leaf>
</r>
XML

got=$(xmlstarlet sel -t -v 'count(//leaf)' "$tmpdir/in.xml")
[[ "$got" == "5" ]] || { printf 'unexpected count: %q\n' "$got" >&2; exit 1; }
