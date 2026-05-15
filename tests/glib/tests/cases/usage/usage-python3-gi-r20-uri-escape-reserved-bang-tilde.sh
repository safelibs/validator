#!/usr/bin/env bash
# @testcase: usage-python3-gi-r20-uri-escape-reserved-bang-tilde
# @title: PyGObject GLib.uri_escape_string leaves unreserved ~ and percent-encodes !
# @description: Calls GLib.uri_escape_string on the literal "hello!~" with no reserved characters and allow_utf8=False, asserting the result equals "hello%21~" since RFC 3986 marks "~" as unreserved (kept verbatim) while "!" is in the reserved set and gets percent-encoded as %21, exercising the URI escape character classification distinct from prior space-only tests.
# @timeout: 60
# @tags: usage, python, uri, escape, r20
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PY'
from gi.repository import GLib

escaped = GLib.uri_escape_string("hello!~", None, False)
print("escaped=" + escaped)
PY

validator_assert_contains "$tmpdir/out" 'escaped=hello%21~'
