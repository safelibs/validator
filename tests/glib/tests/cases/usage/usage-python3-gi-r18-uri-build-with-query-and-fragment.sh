#!/usr/bin/env bash
# @testcase: usage-python3-gi-r18-uri-build-with-query-and-fragment
# @title: PyGObject GLib.Uri.build with explicit query and fragment renders a stable string
# @description: Calls GLib.Uri.build with scheme https, host example.test, path /a/b, query "k=v", and fragment "frag" and asserts the rendered string via to_string starts with "https://example.test/a/b" and ends with the "?k=v#frag" suffix, exercising the structured URI assembler distinct from parse-and-extract tests.
# @timeout: 60
# @tags: usage, python, uri, build, r18
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PY'
from gi.repository import GLib

uri = GLib.Uri.build(
    GLib.UriFlags.NONE,
    "https",
    None,
    "example.test",
    -1,
    "/a/b",
    "k=v",
    "frag",
)
s = uri.to_string()
print("uri=" + s)
PY

validator_assert_contains "$tmpdir/out" 'uri=https://example.test/a/b?k=v#frag'
