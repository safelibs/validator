#!/usr/bin/env bash
# @testcase: usage-python3-gi-r15-checksum-md5-empty-string
# @title: PyGObject GLib.compute_checksum_for_string returns the canonical MD5 of the empty string
# @description: Calls GLib.compute_checksum_for_string with the MD5 algorithm against the empty string '' and length 0, asserting the result equals the canonical MD5 hex digest 'd41d8cd98f00b204e9800998ecf8427e'.
# @timeout: 60
# @tags: usage, python, checksum
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PY'
from gi.repository import GLib
digest = GLib.compute_checksum_for_string(GLib.ChecksumType.MD5, "", 0)
print("digest=" + digest)
PY

validator_assert_contains "$tmpdir/out" 'digest=d41d8cd98f00b204e9800998ecf8427e'
