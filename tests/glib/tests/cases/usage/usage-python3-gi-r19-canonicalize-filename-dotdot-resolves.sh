#!/usr/bin/env bash
# @testcase: usage-python3-gi-r19-canonicalize-filename-dotdot-resolves
# @title: PyGObject GLib.canonicalize_filename resolves dot and dotdot components
# @description: Calls GLib.canonicalize_filename on the path "/a/b/../c/./d" with a None relative-to argument and asserts the returned string equals "/a/c/d" with both the parent-dir and current-dir components removed, exercising the path canonicalisation helper.
# @timeout: 60
# @tags: usage, python, canonicalize-filename, r19
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PY'
from gi.repository import GLib

result = GLib.canonicalize_filename("/a/b/../c/./d", None)
print("canon=" + result)
PY

validator_assert_contains "$tmpdir/out" 'canon=/a/c/d'
