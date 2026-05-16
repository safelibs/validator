#!/usr/bin/env bash
# @testcase: usage-python3-gi-r21-markup-escape-amp-lt-gt-quote
# @title: PyGObject GLib.markup_escape_text escapes all four canonical XML special characters
# @description: Calls GLib.markup_escape_text on the string '&<>"\'' and asserts the returned text equals "&amp;&lt;&gt;&quot;&apos;" (the canonical XML entity escapes for ampersand, less-than, greater-than, double-quote, and apostrophe), exercising the full XML-markup escape set distinct from prior single-char or partial-set escape tests.
# @timeout: 60
# @tags: usage, python, markup, escape, r21
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PY'
from gi.repository import GLib

escaped = GLib.markup_escape_text("&<>\"'", -1)
print("escaped=" + escaped)
print("len=" + str(len(escaped)))
PY

validator_assert_contains "$tmpdir/out" 'escaped=&amp;&lt;&gt;&quot;&apos;'
