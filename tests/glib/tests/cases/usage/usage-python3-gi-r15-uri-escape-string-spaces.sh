#!/usr/bin/env bash
# @testcase: usage-python3-gi-r15-uri-escape-string-spaces
# @title: PyGObject GLib.Uri.escape_string percent-encodes spaces as %20
# @description: Calls GLib.Uri.escape_string('hello world r15', None, False) and asserts the returned encoded string equals 'hello%20world%20r15', confirming spaces are percent-encoded.
# @timeout: 60
# @tags: usage, python, uri, escape
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PY'
from gi.repository import GLib
escaped = GLib.Uri.escape_string("hello world r15", None, False)
print("escaped=" + escaped)
unescaped = GLib.Uri.unescape_string(escaped, None)
print("unescaped=" + unescaped)
PY

validator_assert_contains "$tmpdir/out" 'escaped=hello%20world%20r15'
validator_assert_contains "$tmpdir/out" 'unescaped=hello world r15'
