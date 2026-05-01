#!/usr/bin/env bash
# @testcase: usage-python3-lxml-xpath-eval-error-r7
# @title: lxml XPathEvalError on malformed expression
# @description: Submits a syntactically invalid XPath expression to etree.XPath compilation and verifies the libxml2 backend raises XPathSyntaxError, then submits an undefined function reference to a compiled XPath at evaluation time and verifies XPathEvalError is raised, confirming both error classes are surfaced from the C library.
# @timeout: 120
# @tags: usage, xml, python, xpath, errors
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - >"$tmpdir/out" <<'PY'
from lxml import etree

doc = etree.fromstring(b"<root><item/></root>")

# Compilation-time syntax error.
try:
    etree.XPath("/root[")
except etree.XPathSyntaxError as exc:
    print("syntax-error=True")
else:
    raise AssertionError("expected XPathSyntaxError")

# Evaluation-time error: unknown function call (in null namespace) raises
# XPathEvalError when libxml2 cannot resolve it.
expr = etree.XPath("validator-no-such-function(/root)")
try:
    expr(doc)
except etree.XPathEvalError as exc:
    print("eval-error=True")
else:
    raise AssertionError("expected XPathEvalError")
PY

validator_assert_contains "$tmpdir/out" 'syntax-error=True'
validator_assert_contains "$tmpdir/out" 'eval-error=True'
