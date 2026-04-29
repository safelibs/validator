#!/usr/bin/env bash
# @testcase: usage-python3-gi-uri-unescape-batch11
# @title: PyGObject GLib URI unescape
# @description: Calls GLib URI unescaping through PyGObject.
# @timeout: 180
# @tags: usage, python, glib
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-gi-uri-unescape-batch11"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PYCASE'
from gi.repository import GLib
print(GLib.uri_unescape_string('alpha%20beta', None))
PYCASE
validator_assert_contains "$tmpdir/out" 'alpha beta'
