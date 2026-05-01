#!/usr/bin/env bash
# @testcase: usage-xmlstarlet-validate-dtd-inline-r7
# @title: xmlstarlet val -e verbose DTD diagnostics
# @description: Runs xmlstarlet val -e (verbose) against an external DTD declaring a required attribute and verifies a conforming document is reported "valid" while a non-conforming document is reported "invalid" with verbose, well-formed diagnostics naming the missing required attribute and a non-zero exit code.
# @timeout: 120
# @tags: usage, xml, cli, xmlstarlet, dtd
# @client: xmlstarlet

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/items.dtd" <<'DTD'
<!ELEMENT root (item+)>
<!ELEMENT item (#PCDATA)>
<!ATTLIST item id CDATA #REQUIRED>
DTD

cat >"$tmpdir/good.xml" <<'XML'
<?xml version="1.0"?>
<root><item id="a">alpha</item><item id="b">beta</item></root>
XML

cat >"$tmpdir/bad.xml" <<'XML'
<?xml version="1.0"?>
<root><item>missing-id</item></root>
XML

xmlstarlet val -e -d "$tmpdir/items.dtd" "$tmpdir/good.xml" >"$tmpdir/good-out" 2>&1
validator_assert_contains "$tmpdir/good-out" 'valid'

set +e
xmlstarlet val -e -d "$tmpdir/items.dtd" "$tmpdir/bad.xml" >"$tmpdir/bad-out" 2>&1
bad_status=$?
set -e

[[ "$bad_status" -ne 0 ]] || {
  printf 'expected non-zero exit on DTD-violating doc, got %s\n' "$bad_status" >&2
  cat "$tmpdir/bad-out" >&2
  exit 1
}
validator_assert_contains "$tmpdir/bad-out" 'invalid'
# Verbose mode (-e) must surface the libxml2 diagnostic naming the missing attr.
validator_assert_contains "$tmpdir/bad-out" 'id'

printf 'good-status=0\nbad-status=%s\n' "$bad_status"
