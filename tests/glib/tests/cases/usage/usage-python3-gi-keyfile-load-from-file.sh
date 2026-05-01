#!/usr/bin/env bash
# @testcase: usage-python3-gi-keyfile-load-from-file
# @title: PyGObject GLib KeyFile load_from_file
# @description: Persists a KeyFile to disk and reloads it via GLib.KeyFile.load_from_file through PyGObject, verifying values and group lookup survive the round trip.
# @timeout: 180
# @tags: usage, python, keyfile
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-gi-keyfile-load-from-file"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/data.ini" <<'INI'
[demo]
name=validator
count=7
flag=true

[other]
hello=world
INI

python3 >"$tmpdir/out" <<PY
from gi.repository import GLib

key = GLib.KeyFile()
key.load_from_file("$tmpdir/data.ini", GLib.KeyFileFlags.NONE)

print('name=' + key.get_string('demo', 'name'))
print('count=' + str(key.get_integer('demo', 'count')))
print('flag=' + str(key.get_boolean('demo', 'flag')))
print('hello=' + key.get_string('other', 'hello'))
print('groups=' + ','.join(sorted(key.get_groups()[0])))
print('has_other=' + str(key.has_group('other')))
PY

validator_assert_contains "$tmpdir/out" 'name=validator'
validator_assert_contains "$tmpdir/out" 'count=7'
validator_assert_contains "$tmpdir/out" 'flag=True'
validator_assert_contains "$tmpdir/out" 'hello=world'
validator_assert_contains "$tmpdir/out" 'groups=demo,other'
validator_assert_contains "$tmpdir/out" 'has_other=True'
