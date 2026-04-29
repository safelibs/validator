#!/usr/bin/env bash
# @testcase: schema-xinclude-checks
# @title: Schema and XInclude checks
# @description: Validates XML against a schema and expands an XInclude document.
# @timeout: 120
# @tags: cli, schema

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/schema.xsd" <<'XML'
<xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema"><xs:element name="root"><xs:complexType><xs:sequence><xs:element name="item" type="xs:string"/></xs:sequence></xs:complexType></xs:element></xs:schema>
XML
printf '<root><item>valid</item></root>\n' >"$tmpdir/valid.xml"; xmllint --noout --schema "$tmpdir/schema.xsd" "$tmpdir/valid.xml"; printf '<included>text</included>\n' >"$tmpdir/include.xml"; cat >"$tmpdir/root.xml" <<XML
<root xmlns:xi="http://www.w3.org/2001/XInclude"><xi:include href="$tmpdir/include.xml"/></root>
XML
xmllint --xinclude "$tmpdir/root.xml" | tee "$tmpdir/x.xml"; grep '<included>text</included>' "$tmpdir/x.xml"
