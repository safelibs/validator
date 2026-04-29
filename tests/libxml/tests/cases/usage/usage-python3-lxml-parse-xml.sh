#!/usr/bin/env bash
# @testcase: usage-python3-lxml-parse-xml
# @title: python3-lxml parse xml
# @description: Runs python3-lxml parse xml behavior through libxml2.
# @timeout: 180
# @tags: usage, xml
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
    trap 'rm -rf "$tmpdir"' EXIT

    validator_make_fixture "$tmpdir/in.xml" "<root><item name=\"alpha\">1</item><item name=\"beta\">2</item></root>"
python3 - <<'PY' "$tmpdir/in.xml"
from lxml import etree
import sys
root=etree.parse(sys.argv[1]).getroot(); print(root.find('item').text)
PY
