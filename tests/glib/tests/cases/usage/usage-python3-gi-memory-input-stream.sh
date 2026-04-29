#!/usr/bin/env bash
# @testcase: usage-python3-gi-memory-input-stream
# @title: PyGObject Gio memory input stream
# @description: Reads bytes from a Gio MemoryInputStream through PyGObject and verifies the restored payload.
# @timeout: 180
# @tags: usage, python, gio
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-gi-memory-input-stream"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PYCASE'
from gi.repository import Gio
stream = Gio.MemoryInputStream.new_from_data(b'memory-stream', None)
data = stream.read_bytes(13, None)
print(data.get_data().decode('utf-8'))
PYCASE
validator_assert_contains "$tmpdir/out" 'memory-stream'
