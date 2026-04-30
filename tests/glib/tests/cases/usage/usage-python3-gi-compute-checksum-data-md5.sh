#!/usr/bin/env bash
# @testcase: usage-python3-gi-compute-checksum-data-md5
# @title: PyGObject GLib.compute_checksum_for_data MD5 KAT
# @description: Computes an MD5 digest of a fixed byte sequence with GLib.compute_checksum_for_data through PyGObject and checks the resulting hex string against a known answer.
# @timeout: 180
# @tags: usage, glib, python, checksum
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-gi-compute-checksum-data-md5"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PY'
from gi.repository import GLib
digest = GLib.compute_checksum_for_data(GLib.ChecksumType.MD5, b"payload")
print("md5=" + digest)
PY

validator_assert_contains "$tmpdir/out" 'md5=321c3cf486ed509164edec1e1981fec8'
