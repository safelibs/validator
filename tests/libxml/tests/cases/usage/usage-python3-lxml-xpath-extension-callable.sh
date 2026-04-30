#!/usr/bin/env bash
# @testcase: usage-python3-lxml-xpath-extension-callable
# @title: lxml etree.XPath with extensions dict
# @description: Compiles an etree.XPath expression with a custom extension function passed via the extensions= mapping (rather than via FunctionNamespace), invokes the XPath against an in-memory tree, and verifies the Python callable was called by the libxml2-backed XPath engine and returned the expected aggregated result.
# @timeout: 180
# @tags: usage, xml, python, xpath
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - >"$tmpdir/out" <<'PY'
from lxml import etree

calls = []

def join_text(context, nodes):
    calls.append(len(nodes))
    parts = []
    for n in nodes:
        parts.append((n.text or "").strip())
    return "|".join(parts)

ns = {"ext": "urn:validator-ext"}
xpath = etree.XPath("ext:join(/root/item)", namespaces=ns,
                    extensions={("urn:validator-ext", "join"): join_text})

root = etree.fromstring(b"<root><item>alpha</item><item>beta</item><item>gamma</item></root>")
result = xpath(root)

assert result == "alpha|beta|gamma", result
assert calls == [3], calls

print("result=" + result)
print("calls=" + ",".join(str(c) for c in calls))
PY

validator_assert_contains "$tmpdir/out" 'result=alpha|beta|gamma'
validator_assert_contains "$tmpdir/out" 'calls=3'
