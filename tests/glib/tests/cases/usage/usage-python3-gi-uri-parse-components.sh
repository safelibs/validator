#!/usr/bin/env bash
# @testcase: usage-python3-gi-uri-parse-components
# @title: PyGObject GLib URI parse
# @description: Parses a URI with GLib through PyGObject and verifies the host and path components.
# @timeout: 180
# @tags: usage, python, glib
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-gi-uri-parse-components"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PYCASE'
from gi.repository import GLib
uri = GLib.Uri.parse('https://example.invalid/path?q=1', GLib.UriFlags.NONE)
print(uri.get_host(), uri.get_path())
PYCASE
validator_assert_contains "$tmpdir/out" 'example.invalid /path'
