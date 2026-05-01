#!/usr/bin/env bash
# @testcase: usage-python3-gi-hostname-classification
# @title: PyGObject GLib hostname classification
# @description: Calls GLib.hostname_is_ip_address and hostname_is_non_ascii on representative inputs and verifies IPv4, IPv6, ASCII, and non-ASCII names are classified correctly.
# @timeout: 120
# @tags: usage, glib, python, hostname
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-gi-hostname-classification"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PY'
from gi.repository import GLib

print("ipv4=" + str(GLib.hostname_is_ip_address("10.0.0.5")))
print("ipv6=" + str(GLib.hostname_is_ip_address("::1")))
print("name=" + str(GLib.hostname_is_ip_address("example.org")))
print("nonascii=" + str(GLib.hostname_is_non_ascii("éxample.com")))
print("asciihost=" + str(GLib.hostname_is_non_ascii("example.com")))
print("punycode=" + str(GLib.hostname_is_ascii_encoded("xn--n3h.example")))
PY

validator_assert_contains "$tmpdir/out" 'ipv4=True'
validator_assert_contains "$tmpdir/out" 'ipv6=True'
validator_assert_contains "$tmpdir/out" 'name=False'
validator_assert_contains "$tmpdir/out" 'nonascii=True'
validator_assert_contains "$tmpdir/out" 'asciihost=False'
validator_assert_contains "$tmpdir/out" 'punycode=True'
