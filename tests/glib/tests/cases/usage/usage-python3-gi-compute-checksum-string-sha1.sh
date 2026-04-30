#!/usr/bin/env bash
# @testcase: usage-python3-gi-compute-checksum-string-sha1
# @title: PyGObject GLib.compute_checksum_for_string SHA1 KAT
# @description: Computes a SHA1 digest of a fixed string with GLib.compute_checksum_for_string through PyGObject and checks the resulting hex string against a known answer.
# @timeout: 180
# @tags: usage, glib, python, checksum
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-gi-compute-checksum-string-sha1"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PY'
from gi.repository import GLib
digest = GLib.compute_checksum_for_string(GLib.ChecksumType.SHA1, "payload", -1)
print("sha1=" + digest)
PY

validator_assert_contains "$tmpdir/out" 'sha1=f07e5a815613c5abeddc4b682247a4c42d8a95df'
