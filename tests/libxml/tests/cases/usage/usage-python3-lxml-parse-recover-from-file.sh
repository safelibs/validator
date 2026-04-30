#!/usr/bin/env bash
# @testcase: usage-python3-lxml-parse-recover-from-file
# @title: lxml etree.parse with recover=True from file
# @description: Writes a tiny malformed XML document to disk, parses it through etree.parse using an XMLParser configured with recover=True, and verifies the recovered tree exposes the partial content without raising while the parser's error_log records the recovered errors.
# @timeout: 180
# @tags: usage, xml, python, parser, recover
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Very small malformed XML (mismatched tags).
printf '<root><item>ok</root>' >"$tmpdir/broken.xml"

python3 - "$tmpdir/broken.xml" >"$tmpdir/out" <<'PY'
import sys
from lxml import etree

parser = etree.XMLParser(recover=True)
tree = etree.parse(sys.argv[1], parser)
root = tree.getroot()

assert root.tag == "root", root.tag
text = root.xpath("string(item)")
assert text == "ok", text

# error_log should record at least one recovered error.
errors = list(parser.error_log)
assert len(errors) >= 1, errors

print("root=" + root.tag)
print("item=" + text)
print("errors=" + str(len(errors)))
print("first-error=" + errors[0].message[:40])
PY

validator_assert_contains "$tmpdir/out" 'root=root'
validator_assert_contains "$tmpdir/out" 'item=ok'
validator_assert_contains "$tmpdir/out" 'errors='
