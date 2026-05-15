#!/usr/bin/env bash
# @testcase: usage-xmlstarlet-r20-val-dtd-rejects-missing-required-attribute
# @title: xmlstarlet val -d rejects a document missing a DTD-required attribute with a non-zero exit
# @description: Builds a DTD that declares item with a required 'id' attribute and an instance missing that attribute, runs xmlstarlet val -d against it, and asserts the command exits non-zero, exercising the libxml2 DTD-validation rejection path in xmlstarlet val.
# @timeout: 60
# @tags: usage, xmlstarlet, val, dtd, required-attribute, r20
# @client: xmlstarlet

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/schema.dtd" <<'DTD'
<!ELEMENT root (item+)>
<!ELEMENT item (#PCDATA)>
<!ATTLIST item id CDATA #REQUIRED>
DTD

cat >"$tmpdir/bad.xml" <<'XML'
<?xml version="1.0"?>
<root><item>missing id</item></root>
XML

rc=0
xmlstarlet val -d "$tmpdir/schema.dtd" "$tmpdir/bad.xml" >"$tmpdir/val.log" 2>&1 || rc=$?
(( rc != 0 )) || { echo "expected val to fail with non-zero exit, got 0" >&2; cat "$tmpdir/val.log" >&2; exit 1; }
