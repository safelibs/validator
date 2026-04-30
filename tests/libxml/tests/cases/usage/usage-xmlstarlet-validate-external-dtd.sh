#!/usr/bin/env bash
# @testcase: usage-xmlstarlet-validate-external-dtd
# @title: xmlstarlet validate external DTD
# @description: Validates an XML document against an external DTD file using xmlstarlet val -d, confirming a conforming document is reported valid and that a second document violating the DTD element model is reported invalid with a non-zero exit status.
# @timeout: 180
# @tags: usage, xml, cli, dtd
# @client: xmlstarlet

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-xmlstarlet-validate-external-dtd"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/catalog.dtd" <<'DTD'
<!ELEMENT catalog (book+)>
<!ELEMENT book (title, pages)>
<!ELEMENT title (#PCDATA)>
<!ELEMENT pages (#PCDATA)>
<!ATTLIST book id CDATA #REQUIRED>
DTD

cat >"$tmpdir/good.xml" <<'XML'
<catalog>
  <book id="b1"><title>Alpha</title><pages>120</pages></book>
  <book id="b2"><title>Beta</title><pages>240</pages></book>
</catalog>
XML

cat >"$tmpdir/bad.xml" <<'XML'
<catalog>
  <book id="b3"><pages>50</pages></book>
</catalog>
XML

xmlstarlet val -d "$tmpdir/catalog.dtd" "$tmpdir/good.xml" >"$tmpdir/good-out" 2>&1
validator_assert_contains "$tmpdir/good-out" 'valid'

set +e
xmlstarlet val -d "$tmpdir/catalog.dtd" "$tmpdir/bad.xml" >"$tmpdir/bad-out" 2>&1
bad_status=$?
set -e

[[ "$bad_status" -ne 0 ]] || {
  printf 'expected non-zero exit when validating bad doc, got %s\n' "$bad_status" >&2
  cat "$tmpdir/bad-out" >&2
  exit 1
}
validator_assert_contains "$tmpdir/bad-out" 'invalid'

printf 'good-status=0\nbad-status=%s\n' "$bad_status"
