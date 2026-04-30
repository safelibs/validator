#!/usr/bin/env bash
# @testcase: usage-python3-gi-checksum-bytes-vs-data-parity
# @title: PyGObject GLib checksum_for_bytes equals checksum_for_data
# @description: Hashes the same payload through GLib.compute_checksum_for_bytes (GLib.Bytes input) and GLib.compute_checksum_for_data (raw bytes input) for SHA256 and SHA512 via PyGObject and asserts the two PyGObject entry points produce identical digests.
# @timeout: 180
# @tags: usage, python, glib, checksum
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-gi-checksum-bytes-vs-data-parity"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PY'
from gi.repository import GLib

payload = b"safelibs validator parity"
gbytes = GLib.Bytes.new(payload)

for name, kind in (("sha256", GLib.ChecksumType.SHA256),
                   ("sha512", GLib.ChecksumType.SHA512)):
    via_bytes = GLib.compute_checksum_for_bytes(kind, gbytes)
    via_data = GLib.compute_checksum_for_data(kind, payload)
    print(f"{name}_bytes={via_bytes}")
    print(f"{name}_data={via_data}")
    print(f"{name}_match={via_bytes == via_data}")
PY

validator_assert_contains "$tmpdir/out" 'sha256_match=True'
validator_assert_contains "$tmpdir/out" 'sha512_match=True'
# Pin the digests so a regression in either entry point is caught even
# if the parity check were defeated.
validator_assert_contains "$tmpdir/out" 'sha256_bytes=27a90226022eabb2858e9ddee0a2453b36f8006eb7e86d9e603b919307499a3f'
validator_assert_contains "$tmpdir/out" 'sha256_data=27a90226022eabb2858e9ddee0a2453b36f8006eb7e86d9e603b919307499a3f'
