#!/usr/bin/env bash
# @testcase: usage-python3-gi-markup-escape
# @title: PyGObject GLib markup escape
# @description: Escapes markup-sensitive text with GLib.markup_escape_text through PyGObject.
# @timeout: 180
# @tags: usage, python, glib
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-gi-markup-escape"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PYCASE'
from gi.repository import GLib
print(GLib.markup_escape_text('<alpha>&'))
PYCASE
validator_assert_contains "$tmpdir/out" '&lt;alpha&gt;&amp;'
