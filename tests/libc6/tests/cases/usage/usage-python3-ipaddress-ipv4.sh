#!/usr/bin/env bash
# @testcase: usage-python3-ipaddress-ipv4
# @title: python ipaddress IPv4Address conversion
# @description: Uses ipaddress.IPv4Address to round-trip dotted-quad and integer forms and verifies exact textual output.
# @timeout: 180
# @tags: usage, python
# @client: python3-minimal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-ipaddress-ipv4"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PY'
import ipaddress

addr = ipaddress.IPv4Address("192.168.1.10")
assert int(addr) == 3232235786
assert str(addr) == "192.168.1.10"

back = ipaddress.IPv4Address(3232235786)
assert str(back) == "192.168.1.10"

# is_private must be True for 192.168.0.0/16.
assert addr.is_private is True
assert addr.is_global is False

print("ipv4-int:%d" % int(addr))
print("ipv4-str:%s" % str(back))
print("ipv4-private:%s" % addr.is_private)
PY

test "$(wc -l <"$tmpdir/out")" -eq 3
grep -Fxq 'ipv4-int:3232235786' "$tmpdir/out"
grep -Fxq 'ipv4-str:192.168.1.10' "$tmpdir/out"
grep -Fxq 'ipv4-private:True' "$tmpdir/out"
