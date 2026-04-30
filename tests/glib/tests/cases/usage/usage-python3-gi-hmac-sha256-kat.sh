#!/usr/bin/env bash
# @testcase: usage-python3-gi-hmac-sha256-kat
# @title: PyGObject GLib HMAC-SHA256 known-answer test
# @description: Computes HMAC-SHA256 of a fixed message under a fixed key through GLib.compute_hmac_for_bytes via PyGObject and asserts the digest matches a precomputed RFC-style known-answer.
# @timeout: 180
# @tags: usage, python, glib, hmac
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-gi-hmac-sha256-kat"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PY'
from gi.repository import GLib

key = GLib.Bytes.new(b"key")
msg = GLib.Bytes.new(b"message")
print("hmac=" + GLib.compute_hmac_for_bytes(GLib.ChecksumType.SHA256, key, msg))
PY

# Independently verified known-answer for HMAC-SHA256(key="key", msg="message").
validator_assert_contains "$tmpdir/out" 'hmac=6e9ef29b75fffc5b7abae527d58fdadb2fe42e7219011976917343065f58ed4a'
