#!/usr/bin/env bash
# @testcase: usage-python3-gi-batch12-uri-resolve-relative
# @title: PyGObject GLib.Uri resolve_relative
# @description: Uses GLib.Uri.resolve_relative to resolve a relative path against an absolute base URI and verifies the resolved URI string.
# @timeout: 60
# @tags: usage, python, uri
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PY'
from gi.repository import GLib
base = "https://example.com/a/b/c"
result = GLib.Uri.resolve_relative(base, "../d", GLib.UriFlags.NONE)
print(result)
assert result == "https://example.com/a/d"
PY
validator_assert_contains "$tmpdir/out" 'https://example.com/a/d'
