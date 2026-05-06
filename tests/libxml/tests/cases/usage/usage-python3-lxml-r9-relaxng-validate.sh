#!/usr/bin/env bash
# @testcase: usage-python3-lxml-r9-relaxng-validate
# @title: lxml RelaxNG validate accepts and rejects
# @description: Compiles a RelaxNG schema and verifies it accepts a conforming document and rejects a non-conforming one.
# @timeout: 60
# @tags: usage, python3-lxml, relaxng
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY'
from lxml import etree
rng_src = b"""<?xml version='1.0'?>
<element name='note' xmlns='http://relaxng.org/ns/structure/1.0'>
  <element name='title'><text/></element>
</element>"""
rng = etree.RelaxNG(etree.fromstring(rng_src))
ok = etree.fromstring(b'<note><title>hi</title></note>')
bad = etree.fromstring(b'<note><body>hi</body></note>')
assert rng.validate(ok) is True, rng.error_log
assert rng.validate(bad) is False
PY
