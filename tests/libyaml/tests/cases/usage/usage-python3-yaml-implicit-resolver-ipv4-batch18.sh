#!/usr/bin/env bash
# @testcase: usage-python3-yaml-implicit-resolver-ipv4-batch18
# @title: PyYAML SafeLoader.add_implicit_resolver matches IPv4 dotted-quad scalars
# @description: Subclasses yaml.SafeLoader and registers an add_implicit_resolver bound to a fresh "!ipv4" tag with a dotted-quad regex and the digit "first" set, paired with a constructor that wraps the raw scalar in a tagged tuple. Verifies plain scalars matching the IPv4 pattern are dispatched to the constructor while non-matching scalars (a hostname, a plain word) keep the default string tag, and that the regex does not collide with PyYAML's built-in float resolver because the input has more than one dot.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-implicit-resolver-ipv4-batch18"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir/out"
import re
import sys
import yaml

case_id = sys.argv[1]
out_path = sys.argv[2]

class IPLoader(yaml.SafeLoader):
    pass

IPV4_TAG = "!ipv4"
IPLoader.add_implicit_resolver(
    IPV4_TAG,
    re.compile(r"^(?:\d{1,3}\.){3}\d{1,3}$"),
    list("0123456789"),
)

def construct_ipv4(loader, node):
    raw = loader.construct_scalar(node)
    return ("ipv4", raw)

IPLoader.add_constructor(IPV4_TAG, construct_ipv4)

doc = (
    "gateway: 192.168.1.1\n"
    "loopback: 127.0.0.1\n"
    "host: example.org\n"
    "label: hello\n"
)

data = yaml.load(doc, Loader=IPLoader)

assert data["gateway"] == ("ipv4", "192.168.1.1"), data
assert data["loopback"] == ("ipv4", "127.0.0.1"), data
# Hostnames and labels do not match the IPv4 regex and stay strings.
assert data["host"] == "example.org", data
assert isinstance(data["host"], str), type(data["host"])
assert data["label"] == "hello", data

# Sanity: the same document under SafeLoader has only string values for
# the dotted-quad fields, proving the resolver did the work.
plain = yaml.safe_load(doc)
assert plain["gateway"] == "192.168.1.1", plain
assert isinstance(plain["gateway"], str), type(plain["gateway"])

with open(out_path, "w", encoding="utf-8") as fh:
    fh.write(f"gateway={data['gateway']}\n")
    fh.write(f"loopback={data['loopback']}\n")
    fh.write(f"host={data['host']}\n")
    fh.write(f"plain_gateway={plain['gateway']}\n")

print("OK")
PYCASE

validator_assert_contains "$tmpdir/out" "gateway=('ipv4', '192.168.1.1')"
validator_assert_contains "$tmpdir/out" "loopback=('ipv4', '127.0.0.1')"
validator_assert_contains "$tmpdir/out" "plain_gateway=192.168.1.1"
echo "OK"
