#!/usr/bin/env bash
# @testcase: usage-python3-gi-r21-uri-parse-userinfo-component
# @title: PyGObject GLib.Uri.parse extracts userinfo from https://user:pass@host/path
# @description: Calls GLib.Uri.parse on the URI "https://alice:secret@example.com:443/api" with NONE flags and asserts the resulting GUri.get_userinfo() returns "alice:secret", get_host() returns "example.com", get_port() returns 443 and get_scheme() returns "https", exercising the userinfo extraction distinct from the existing scheme/host/port and query-component parse tests.
# @timeout: 60
# @tags: usage, python, uri, userinfo, r21
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PY'
from gi.repository import GLib

uri = GLib.Uri.parse("https://alice:secret@example.com:443/api", GLib.UriFlags.NONE)
print("scheme=" + uri.get_scheme())
print("userinfo=" + (uri.get_userinfo() or ""))
print("host=" + uri.get_host())
print("port=" + str(uri.get_port()))
print("path=" + uri.get_path())
PY

validator_assert_contains "$tmpdir/out" 'scheme=https'
validator_assert_contains "$tmpdir/out" 'userinfo=alice:secret'
validator_assert_contains "$tmpdir/out" 'host=example.com'
validator_assert_contains "$tmpdir/out" 'port=443'
validator_assert_contains "$tmpdir/out" 'path=/api'
