#!/usr/bin/env bash
# @testcase: usage-python3-gi-filename-uri-roundtrip
# @title: PyGObject GLib filename_to_uri roundtrip
# @description: Converts a path containing whitespace to a file:// URI with GLib.filename_to_uri and converts it back with GLib.filename_from_uri, verifying percent-encoding and the recovered path.
# @timeout: 120
# @tags: usage, glib, python, uri
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-gi-filename-uri-roundtrip"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PY'
from gi.repository import GLib

src = "/tmp/foo bar.txt"
uri = GLib.filename_to_uri(src, None)
print("uri=" + uri)

result = GLib.filename_from_uri(uri)
# Returns a tuple (filename, hostname); hostname is None for local paths.
filename, hostname = result[0], result[1]
print("filename=" + filename)
print("hostname=" + ("<none>" if hostname is None else hostname))
PY

validator_assert_contains "$tmpdir/out" 'uri=file:///tmp/foo%20bar.txt'
validator_assert_contains "$tmpdir/out" 'filename=/tmp/foo bar.txt'
validator_assert_contains "$tmpdir/out" 'hostname=<none>'
