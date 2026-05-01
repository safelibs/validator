#!/usr/bin/env bash
# @testcase: usage-python3-gi-uri-list-extract
# @title: PyGObject GLib uri_list_extract_uris
# @description: Splits a text/uri-list payload through GLib.uri_list_extract_uris and verifies comment lines are dropped while three URIs are preserved in order.
# @timeout: 120
# @tags: usage, glib, python, uri
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-gi-uri-list-extract"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PY'
from gi.repository import GLib

payload = "http://a.example/path\r\nhttps://b.example/\r\n#comment\r\nftp://c.example/x\r\n"
uris = GLib.uri_list_extract_uris(payload)
print("count=" + str(len(uris)))
for u in uris:
    print("uri=" + u)
PY

validator_assert_contains "$tmpdir/out" 'count=3'
validator_assert_contains "$tmpdir/out" 'uri=http://a.example/path'
validator_assert_contains "$tmpdir/out" 'uri=https://b.example/'
validator_assert_contains "$tmpdir/out" 'uri=ftp://c.example/x'
