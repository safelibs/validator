#!/usr/bin/env bash
# @testcase: usage-python3-gi-checksum-sha1
# @title: PyGObject GLib SHA1 checksum
# @description: Computes a SHA1 digest through GLib Checksum from PyGObject.
# @timeout: 180
# @tags: usage, python, checksum
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-gi-checksum-sha1"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PYCASE'
from gi.repository import GLib
checksum = GLib.Checksum.new(GLib.ChecksumType.SHA1)
checksum.update(b'abc')
print(checksum.get_string())
PYCASE
validator_assert_contains "$tmpdir/out" 'a9993e364706816aba3e25717850c26c9cd0d89d'
