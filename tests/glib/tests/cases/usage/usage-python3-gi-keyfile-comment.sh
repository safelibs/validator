#!/usr/bin/env bash
# @testcase: usage-python3-gi-keyfile-comment
# @title: PyGObject GLib KeyFile comment roundtrip
# @description: Sets a top comment on a GLib.KeyFile group through PyGObject and verifies it round-trips through to_data and reload.
# @timeout: 180
# @tags: usage, glib, python
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-gi-keyfile-comment"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PY'
from gi.repository import GLib

key = GLib.KeyFile()
key.set_string("demo", "name", "alpha")
key.set_comment("demo", None, " demo group comment")

serialized, _length = key.to_data()
# emit a marker so the bash side can grep the dumped key/value too
print("SERIALIZED-START")
print(serialized)
print("SERIALIZED-END")

reloaded = GLib.KeyFile()
reloaded.load_from_data(serialized, len(serialized), GLib.KeyFileFlags.KEEP_COMMENTS)
print("name=" + reloaded.get_string("demo", "name"))
print("comment=" + reloaded.get_comment("demo", None).strip())
PY

validator_assert_contains "$tmpdir/out" '[demo]'
validator_assert_contains "$tmpdir/out" 'name=alpha'
validator_assert_contains "$tmpdir/out" 'comment=demo group comment'
