#!/usr/bin/env bash
# @testcase: usage-python3-gi-keyfile-groups
# @title: PyGObject GLib KeyFile groups
# @description: Loads multiple INI groups through GLib KeyFile and lists the group names with PyGObject.
# @timeout: 180
# @tags: usage, python, keyfile
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-gi-keyfile-groups"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PYCASE'
from gi.repository import GLib
payload = '[first]\na=1\n[second]\nb=2\n'
key = GLib.KeyFile()
key.load_from_data(payload, len(payload), GLib.KeyFileFlags.NONE)
groups, _length = key.get_groups()
print(','.join(groups))
PYCASE
validator_assert_contains "$tmpdir/out" 'first,second'
