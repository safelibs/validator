#!/usr/bin/env bash
# @testcase: usage-python3-gi-batch12-keyfile-set-list-separator
# @title: PyGObject GLib.KeyFile custom list separator
# @description: Configures a GLib.KeyFile with a custom list separator and verifies get_string_list parses values split by that separator.
# @timeout: 60
# @tags: usage, python, keyfile
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PY'
from gi.repository import GLib
key = GLib.KeyFile()
key.set_list_separator(ord("|"))
data = "[group]\nitems=a|b|c|d\n"
key.load_from_data(data, len(data), GLib.KeyFileFlags.NONE)
items = key.get_string_list("group", "items")
print("count", len(items))
print("joined", ",".join(items))
assert items == ["a", "b", "c", "d"]
PY
validator_assert_contains "$tmpdir/out" 'count 4'
validator_assert_contains "$tmpdir/out" 'joined a,b,c,d'
