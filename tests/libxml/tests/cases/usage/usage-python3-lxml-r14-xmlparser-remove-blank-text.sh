#!/usr/bin/env bash
# @testcase: usage-python3-lxml-r14-xmlparser-remove-blank-text
# @title: lxml etree.XMLParser(remove_blank_text=True) drops whitespace-only text nodes during parsing
# @description: Parses an indented document with etree.XMLParser(remove_blank_text=True), serializes the tree back, and asserts the output is the compact form (no whitespace text nodes between elements). Compares against a default-parser parse of the same input which preserves the indentation.
# @timeout: 60
# @tags: usage, xml, python, parser
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - >"$tmpdir/out" <<'PY'
from lxml import etree

src = b'<r>\n  <a>x</a>\n  <b>y</b>\n</r>'

stripped_parser = etree.XMLParser(remove_blank_text=True)
stripped = etree.fromstring(src, stripped_parser)
print('stripped=' + etree.tostring(stripped).decode())

# Default parser keeps whitespace text nodes verbatim.
keep = etree.fromstring(src)
print('keep_first_text=' + repr(keep.text))
print('stripped_first_text=' + repr(stripped.text))
print('child_count=' + str(len(stripped)))
PY

validator_assert_contains "$tmpdir/out" 'stripped=<r><a>x</a><b>y</b></r>'
validator_assert_contains "$tmpdir/out" 'stripped_first_text=None'
validator_assert_contains "$tmpdir/out" 'child_count=2'
# Default parse preserves the leading whitespace text node.
grep -E "^keep_first_text='\\\\n  '" "$tmpdir/out" >/dev/null || {
    printf 'expected default parser to preserve whitespace text node\n' >&2
    cat "$tmpdir/out" >&2
    exit 1
}
