#!/usr/bin/env bash
# @testcase: usage-python3-gi-r13-checksum-sha256-string-kat
# @title: PyGObject GLib.Checksum incremental SHA256 matches the FIPS 'abc' KAT
# @description: Builds a GLib.Checksum with ChecksumType.SHA256, feeds the bytes of 'abc' through update, and asserts get_string returns the canonical FIPS 180-4 KAT digest ba7816bf...20015ad.
# @timeout: 60
# @tags: usage, python, checksum, sha256
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PY'
from gi.repository import GLib

cs = GLib.Checksum.new(GLib.ChecksumType.SHA256)
cs.update(b"abc")
print("digest=" + cs.get_string())
PY

validator_assert_contains "$tmpdir/out" 'digest=ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad'
