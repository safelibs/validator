#!/usr/bin/env bash
# @testcase: usage-python3-gi-uri-build
# @title: PyGObject GLib Uri build
# @description: Constructs a URI from components with GLib.Uri.build through PyGObject and verifies the serialized string.
# @timeout: 180
# @tags: usage, glib, python
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-gi-uri-build"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PY'
from gi.repository import GLib
uri = GLib.Uri.build(
    GLib.UriFlags.NONE,
    "https",     # scheme
    None,        # userinfo
    "example.invalid",
    8443,
    "/build/path",
    "k=v",
    None,
)
print(uri.to_string())
PY

validator_assert_contains "$tmpdir/out" 'https://example.invalid:8443/build/path?k=v'
