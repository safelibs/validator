#!/usr/bin/env bash
# @testcase: usage-python3-gi-r16-uri-parse-scheme-host-port
# @title: PyGObject GLib.Uri.parse extracts scheme/host/port from a typical URI
# @description: Calls GLib.Uri.parse against "https://example.com:8443/path?q=r16" with GLib.UriFlags.NONE and asserts the returned object exposes scheme='https', host='example.com', and port=8443, exercising the GLib URI parser through Python bindings.
# @timeout: 60
# @tags: usage, python, uri
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PY'
from gi.repository import GLib
uri = GLib.Uri.parse("https://example.com:8443/path?q=r16", GLib.UriFlags.NONE)
print("scheme=" + uri.get_scheme())
print("host=" + uri.get_host())
print("port=" + str(uri.get_port()))
PY

validator_assert_contains "$tmpdir/out" 'scheme=https'
validator_assert_contains "$tmpdir/out" 'host=example.com'
validator_assert_contains "$tmpdir/out" 'port=8443'
