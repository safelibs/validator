#!/usr/bin/env bash
# @testcase: usage-python3-gi-r14-gio-file-parse-name-roundtrip
# @title: PyGObject Gio.File.parse_name builds a GFile whose path matches the input
# @description: Calls Gio.File.parse_name with an absolute filesystem path and asserts the returned GFile reports get_path equal to the input and get_uri starts with the 'file://' scheme prefix.
# @timeout: 60
# @tags: usage, python, gio, file
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir "$tmpdir/r14"

python3 - "$tmpdir/r14" >"$tmpdir/out" <<'PY'
import sys
from gi.repository import Gio
path = sys.argv[1]
f = Gio.File.parse_name(path)
print("path", f.get_path())
print("uri_prefix", f.get_uri().startswith("file://"))
print("basename", f.get_basename())
PY

validator_assert_contains "$tmpdir/out" "path $tmpdir/r14"
validator_assert_contains "$tmpdir/out" 'uri_prefix True'
validator_assert_contains "$tmpdir/out" 'basename r14'
