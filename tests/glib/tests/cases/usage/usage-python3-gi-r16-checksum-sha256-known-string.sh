#!/usr/bin/env bash
# @testcase: usage-python3-gi-r16-checksum-sha256-known-string
# @title: PyGObject GLib.compute_checksum_for_string returns the canonical SHA256 of "abc"
# @description: Calls GLib.compute_checksum_for_string with the SHA256 algorithm against the ASCII string "abc" and length 3 and asserts the result equals the canonical SHA256 hex digest ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad.
# @timeout: 60
# @tags: usage, python, checksum, sha256
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PY'
from gi.repository import GLib
digest = GLib.compute_checksum_for_string(GLib.ChecksumType.SHA256, "abc", 3)
print("digest=" + digest)
PY

validator_assert_contains "$tmpdir/out" 'digest=ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad'
