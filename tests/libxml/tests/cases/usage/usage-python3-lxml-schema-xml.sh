#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
    trap 'rm -rf "$tmpdir"' EXIT

    validator_make_fixture "$tmpdir/in.xml" "<root><item name=\"alpha\">1</item><item name=\"beta\">2</item></root>"
python3 - <<'PY' "$tmpdir/in.xml"
from lxml import etree
import sys
schema=etree.XMLSchema(etree.XML(b'<xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema"><xs:element name="root"><xs:complexType><xs:sequence><xs:element name="item" maxOccurs="unbounded"/></xs:sequence></xs:complexType></xs:element></xs:schema>')); print(schema.validate(etree.parse(sys.argv[1])))
PY