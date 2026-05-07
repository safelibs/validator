#!/usr/bin/env bash
# @testcase: usage-python3-gi-r13-uri-parse-query-component
# @title: PyGObject GLib.Uri.parse exposes scheme, host, path, and query components
# @description: Parses an https URL with a query string through GLib.Uri.parse and asserts get_scheme, get_host, get_path, and get_query each return the expected component.
# @timeout: 60
# @tags: usage, python, uri, parse
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PY'
from gi.repository import GLib

uri = GLib.Uri.parse("https://safelibs.example/r13/path?lang=en&id=42", GLib.UriFlags.NONE)
print("scheme=" + uri.get_scheme())
print("host=" + uri.get_host())
print("path=" + uri.get_path())
print("query=" + uri.get_query())
PY

validator_assert_contains "$tmpdir/out" 'scheme=https'
validator_assert_contains "$tmpdir/out" 'host=safelibs.example'
validator_assert_contains "$tmpdir/out" 'path=/r13/path'
validator_assert_contains "$tmpdir/out" 'query=lang=en&id=42'
