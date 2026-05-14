#!/usr/bin/env bash
# @testcase: usage-python3-gi-r17-markup-parse-element-count
# @title: PyGObject GLib.MarkupParseContext.parse processes a 3-element XML fragment without error
# @description: Builds a GLib.MarkupParser with empty callbacks, feeds a short XML fragment containing three sibling elements through GLib.MarkupParseContext.parse, calls end_parse, and asserts both calls return without raising, exercising the markup-parser construction path on a well-formed input.
# @timeout: 60
# @tags: usage, python, markup
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PY'
from gi.repository import GLib

parser = GLib.MarkupParser()
ctx = GLib.MarkupParseContext.new(parser, GLib.MarkupParseFlags(0), None)
fragment = "<root><a/><b/><c/></root>"
ok_parse = ctx.parse(fragment, len(fragment))
ok_end = ctx.end_parse()
print("parse_ok=" + str(bool(ok_parse)))
print("end_ok=" + str(bool(ok_end)))
PY

validator_assert_contains "$tmpdir/out" 'parse_ok=True'
validator_assert_contains "$tmpdir/out" 'end_ok=True'
