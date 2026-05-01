#!/usr/bin/env bash
# @testcase: usage-xmlstarlet-validate-dtd-inline-r7
# @title: xmlstarlet val with internal DTD subset
# @description: Validates an XML document carrying an internal DTD subset that requires a mandatory attribute on each item element, runs xmlstarlet val without the -d flag to exercise libxml2's internal-subset validator, and verifies a conforming document validates while a document missing the required attribute is rejected with a non-zero exit and an "invalid" report line.
# @timeout: 120
# @tags: usage, xml, cli, xmlstarlet, dtd
# @client: xmlstarlet

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/good.xml" <<'XML'
<?xml version="1.0"?>
<!DOCTYPE root [
  <!ELEMENT root (item+)>
  <!ELEMENT item (#PCDATA)>
  <!ATTLIST item id CDATA #REQUIRED>
]>
<root><item id="a">alpha</item><item id="b">beta</item></root>
XML

cat >"$tmpdir/bad.xml" <<'XML'
<?xml version="1.0"?>
<!DOCTYPE root [
  <!ELEMENT root (item+)>
  <!ELEMENT item (#PCDATA)>
  <!ATTLIST item id CDATA #REQUIRED>
]>
<root><item>missing-id</item></root>
XML

xmlstarlet val --err "$tmpdir/good.xml" >"$tmpdir/good-out" 2>&1
validator_assert_contains "$tmpdir/good-out" 'valid'

set +e
xmlstarlet val --err "$tmpdir/bad.xml" >"$tmpdir/bad-out" 2>&1
bad_status=$?
set -e

[[ "$bad_status" -ne 0 ]] || {
  printf 'expected non-zero exit on internal-DTD-violating doc, got %s\n' "$bad_status" >&2
  cat "$tmpdir/bad-out" >&2
  exit 1
}
validator_assert_contains "$tmpdir/bad-out" 'invalid'
