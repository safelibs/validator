#!/usr/bin/env bash
# @testcase: usage-xmlstarlet-r21-val-xsd-rejects-violation
# @title: xmlstarlet val -s exits non-zero for a document that violates the XSD's xs:integer typing
# @description: Builds an XSD requiring <num> to be xs:integer and an instance with <num>not-a-number</num>, runs xmlstarlet val -s and asserts the validator exits non-zero — pinning xmlstarlet's libxml2 XSD-validation rejection path on Ubuntu 24.04.
# @timeout: 60
# @tags: usage, xmlstarlet, val, xsd, reject, r21
# @client: xmlstarlet

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/s.xsd" <<'XSD'
<?xml version="1.0"?>
<xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema">
  <xs:element name="num" type="xs:integer"/>
</xs:schema>
XSD

cat >"$tmpdir/bad.xml" <<'XML'
<?xml version="1.0"?>
<num>not-a-number</num>
XML

rc=0
xmlstarlet val -s "$tmpdir/s.xsd" "$tmpdir/bad.xml" >"$tmpdir/val.log" 2>&1 || rc=$?
(( rc != 0 )) || { echo "expected val -s to fail with non-zero exit, got 0" >&2; cat "$tmpdir/val.log" >&2; exit 1; }
