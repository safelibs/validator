#!/usr/bin/env bash
# @testcase: usage-python3-gi-uri-parse-guri-inspection
# @title: PyGObject GLib.Uri.parse exposes full GUri inspection
# @description: Parses an authority-rich URI into a GUri through PyGObject and verifies scheme, user, password, host, port, path, query, and fragment accessors all return the expected components.
# @timeout: 180
# @tags: usage, glib, python, uri
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-gi-uri-parse-guri-inspection"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PY'
from gi.repository import GLib

uri = GLib.Uri.parse(
    'https://alice:secret@example.invalid:8443/some/path?query=1&q2=2#frag',
    GLib.UriFlags.HAS_PASSWORD,
)
print('scheme=' + uri.get_scheme())
print('userinfo=' + uri.get_userinfo())
print('user=' + uri.get_user())
print('password=' + uri.get_password())
print('host=' + uri.get_host())
print('port=' + str(uri.get_port()))
print('path=' + uri.get_path())
print('query=' + uri.get_query())
print('fragment=' + uri.get_fragment())
PY

validator_assert_contains "$tmpdir/out" 'scheme=https'
validator_assert_contains "$tmpdir/out" 'userinfo=alice:secret'
validator_assert_contains "$tmpdir/out" 'user=alice'
validator_assert_contains "$tmpdir/out" 'password=secret'
validator_assert_contains "$tmpdir/out" 'host=example.invalid'
validator_assert_contains "$tmpdir/out" 'port=8443'
validator_assert_contains "$tmpdir/out" 'path=/some/path'
validator_assert_contains "$tmpdir/out" 'query=query=1&q2=2'
validator_assert_contains "$tmpdir/out" 'fragment=frag'
