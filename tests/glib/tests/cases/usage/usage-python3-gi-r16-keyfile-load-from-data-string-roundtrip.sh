#!/usr/bin/env bash
# @testcase: usage-python3-gi-r16-keyfile-load-from-data-string-roundtrip
# @title: PyGObject GLib.KeyFile.load_from_data parses a literal INI string and returns the stored value
# @description: Builds an INI document with a [section] header and key=value pair, passes it to GLib.KeyFile.load_from_data with GLib.KeyFileFlags.NONE, and asserts get_string('section', 'key') returns the original literal value, exercising the in-memory load path distinct from set/get round-trips.
# @timeout: 60
# @tags: usage, python, keyfile, load
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PY'
from gi.repository import GLib
data = "[r16]\nkey=hello-r16\n"
kf = GLib.KeyFile()
kf.load_from_data(data, len(data), GLib.KeyFileFlags.NONE)
print("value=" + kf.get_string("r16", "key"))
print("has=" + str(kf.has_group("r16")))
PY

validator_assert_contains "$tmpdir/out" 'value=hello-r16'
validator_assert_contains "$tmpdir/out" 'has=True'
