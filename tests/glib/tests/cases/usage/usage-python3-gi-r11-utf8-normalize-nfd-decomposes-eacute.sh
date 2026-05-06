#!/usr/bin/env bash
# @testcase: usage-python3-gi-r11-utf8-normalize-nfd-decomposes-eacute
# @title: PyGObject GLib.utf8_normalize NFD decomposes precomposed e-acute
# @description: Calls GLib.utf8_normalize with NormalizeMode.NFD on a precomposed U+00E9 (e-acute), and verifies the result decomposes to two codepoints U+0065 U+0301 (Latin small e plus combining acute), distinct from the NFC roundtrip which preserves the single precomposed codepoint.
# @timeout: 60
# @tags: usage, python, unicode, normalize
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PY'
from gi.repository import GLib
src = "é"  # precomposed
nfd = GLib.utf8_normalize(src, -1, GLib.NormalizeMode.NFD)
nfc = GLib.utf8_normalize(src, -1, GLib.NormalizeMode.NFC)
print("nfd-codepoints", " ".join(f"{ord(c):04x}" for c in nfd))
print("nfc-codepoints", " ".join(f"{ord(c):04x}" for c in nfc))
print("nfd-len", len(nfd))
print("nfc-len", len(nfc))
PY

validator_assert_contains "$tmpdir/out" 'nfd-codepoints 0065 0301'
validator_assert_contains "$tmpdir/out" 'nfc-codepoints 00e9'
validator_assert_contains "$tmpdir/out" 'nfd-len 2'
validator_assert_contains "$tmpdir/out" 'nfc-len 1'
