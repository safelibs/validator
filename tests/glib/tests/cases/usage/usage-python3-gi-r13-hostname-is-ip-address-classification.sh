#!/usr/bin/env bash
# @testcase: usage-python3-gi-r13-hostname-is-ip-address-classification
# @title: PyGObject GLib.hostname_is_ip_address classifies IPv4, IPv6, and DNS labels distinctly
# @description: Calls GLib.hostname_is_ip_address on three representative inputs (192.168.0.1, ::1, and example.com) and asserts the boolean classification distinguishes the two literal IPs from a DNS hostname.
# @timeout: 60
# @tags: usage, python, hostname
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PY'
from gi.repository import GLib

print("ipv4=" + str(GLib.hostname_is_ip_address("192.168.0.1")))
print("ipv6=" + str(GLib.hostname_is_ip_address("::1")))
print("dns=" + str(GLib.hostname_is_ip_address("example.com")))
PY

validator_assert_contains "$tmpdir/out" 'ipv4=True'
validator_assert_contains "$tmpdir/out" 'ipv6=True'
validator_assert_contains "$tmpdir/out" 'dns=False'
