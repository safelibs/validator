#!/usr/bin/env bash
# @testcase: usage-python3-gi-bytes-size-payload
# @title: PyGObject GLib bytes size
# @description: Allocates a GLib Bytes object through PyGObject and verifies the exposed byte size.
# @timeout: 180
# @tags: usage, python, glib
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-gi-bytes-size-payload"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PYCASE'
from gi.repository import GLib
value = GLib.Bytes.new(b'validator-bytes')
print(value.get_size())
PYCASE
validator_assert_contains "$tmpdir/out" '15'
