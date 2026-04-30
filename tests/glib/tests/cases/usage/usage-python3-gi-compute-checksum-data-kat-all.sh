#!/usr/bin/env bash
# @testcase: usage-python3-gi-compute-checksum-data-kat-all
# @title: PyGObject GLib.compute_checksum_for_data MD5 SHA256 SHA384 SHA512 KAT
# @description: Computes MD5, SHA256, SHA384, and SHA512 digests of a fixed byte sequence with GLib.compute_checksum_for_data through PyGObject and checks every hex digest against a known answer.
# @timeout: 180
# @tags: usage, glib, python, checksum
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-gi-compute-checksum-data-kat-all"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PY'
from gi.repository import GLib

payload = b"safelibs validator payload"
algos = (
    ("md5", GLib.ChecksumType.MD5),
    ("sha256", GLib.ChecksumType.SHA256),
    ("sha384", GLib.ChecksumType.SHA384),
    ("sha512", GLib.ChecksumType.SHA512),
)
for name, kind in algos:
    digest = GLib.compute_checksum_for_data(kind, payload)
    print(f"{name}={digest}")
PY

# Known-answer digests for "safelibs validator payload" (26 bytes ASCII).
validator_assert_contains "$tmpdir/out" 'md5=049438af269a1cf81c36750f75b54b6b'
validator_assert_contains "$tmpdir/out" 'sha256=351ed095c8e77807800535e3f0fd001e7ce2f108b21100bbfc154d4fb274f822'
validator_assert_contains "$tmpdir/out" 'sha384=cf84d49e1b191183bdbe653f2504be5c8d2af9ccba48162b5075c465cbd35ec4bddac8b1061a734a57047b80555cb499'
validator_assert_contains "$tmpdir/out" 'sha512=3380f199e272a49e76cdeef258132a671591e2f9a288aece13e0c6365755a51f79877b5662d9093204328b31c7425827bec5a63b01e5ba8a0c9d1c10faf303bd'
