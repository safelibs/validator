#!/usr/bin/env bash
# @testcase: usage-python3-lxml-htmlparser-table
# @title: lxml HTMLParser table structure
# @description: Parses an HTML fragment containing a table with a thead and tbody through lxml.etree.HTMLParser, then verifies that the parser auto-completes the document structure and that the row, cell, and text counts in the resulting tree match the input layout.
# @timeout: 180
# @tags: usage, xml, html, python
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/table.html" <<'HTML'
<!doctype html>
<html><body>
<table id="grid">
  <thead><tr><th>name</th><th>weight</th></tr></thead>
  <tbody>
    <tr><td>alpha</td><td>2</td></tr>
    <tr><td>beta</td><td>3</td></tr>
    <tr><td>gamma</td><td>5</td></tr>
  </tbody>
</table>
</body></html>
HTML

HTML_PATH="$tmpdir/table.html" python3 - >"$tmpdir/out" <<'PY'
import os
from lxml import etree

parser = etree.HTMLParser(no_network=True)
tree = etree.parse(os.environ["HTML_PATH"], parser)
root = tree.getroot()

assert root.tag == "html", root.tag

table = root.find(".//table[@id='grid']")
assert table is not None, etree.tostring(root)

thead_rows = table.findall(".//thead/tr")
tbody_rows = table.findall(".//tbody/tr")
assert len(thead_rows) == 1, len(thead_rows)
assert len(tbody_rows) == 3, len(tbody_rows)

headers = [th.text for th in table.findall(".//thead/tr/th")]
assert headers == ["name", "weight"], headers

names = [tr.findtext("td[1]") for tr in tbody_rows]
weights = [tr.findtext("td[2]") for tr in tbody_rows]
assert names == ["alpha", "beta", "gamma"], names
assert weights == ["2", "3", "5"], weights

print("thead-rows=" + str(len(thead_rows)))
print("tbody-rows=" + str(len(tbody_rows)))
print("headers=" + ",".join(headers))
print("names=" + ",".join(names))
print("weights=" + ",".join(weights))
PY

validator_assert_contains "$tmpdir/out" 'thead-rows=1'
validator_assert_contains "$tmpdir/out" 'tbody-rows=3'
validator_assert_contains "$tmpdir/out" 'headers=name,weight'
validator_assert_contains "$tmpdir/out" 'names=alpha,beta,gamma'
validator_assert_contains "$tmpdir/out" 'weights=2,3,5'
