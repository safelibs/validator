#!/usr/bin/env bash
# @testcase: usage-python3-gi-r15-gio-file-make-directory
# @title: PyGObject Gio.File.make_directory creates a fresh directory on disk
# @description: Builds a Gio.File for a non-existent path under tmpdir, calls make_directory(None), and asserts os.path.isdir reports the new path as an existing directory after the call.
# @timeout: 60
# @tags: usage, python, gio
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<PY
import os
from gi.repository import Gio
target = "$tmpdir/r15-newdir"
gf = Gio.File.new_for_path(target)
gf.make_directory(None)
print("isdir=" + str(os.path.isdir(target)))
print("query=" + gf.query_info("standard::type", Gio.FileQueryInfoFlags.NONE, None).get_attribute_as_string("standard::type"))
PY

validator_assert_contains "$tmpdir/out" 'isdir=True'
# Gio.FileType.DIRECTORY enum is 2.
validator_assert_contains "$tmpdir/out" 'query=2'
