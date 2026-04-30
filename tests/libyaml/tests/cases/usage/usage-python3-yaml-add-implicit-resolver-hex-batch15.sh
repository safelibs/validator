#!/usr/bin/env bash
# @testcase: usage-python3-yaml-add-implicit-resolver-hex-batch15
# @title: PyYAML SafeLoader add_implicit_resolver for ^0x[0-9a-f]+$
# @description: Subclasses yaml.SafeLoader and registers an add_implicit_resolver bound to a fresh "!hex" tag with the regex ^0x[0-9a-f]+$ together with a constructor that parses the hex digits to an int. Verifies plain scalars matching the pattern are wrapped to the integer value while non-matching scalars (decimal ints, plain strings) keep their default tag resolution.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-add-implicit-resolver-hex-batch15"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir/out"
import re
import sys
import yaml

case_id = sys.argv[1]
out_path = sys.argv[2]

class HexLoader(yaml.SafeLoader):
    pass

HEX_TAG = "!hex"
HexLoader.add_implicit_resolver(
    HEX_TAG,
    re.compile(r"^0x[0-9a-f]+$"),
    list("0"),
)

def construct_hex(loader, node):
    raw = loader.construct_scalar(node)
    return int(raw, 16)

HexLoader.add_constructor(HEX_TAG, construct_hex)

doc = (
    "mask: 0xff\n"
    "addr: 0xdeadbeef\n"
    "label: hello\n"
    "decimal: 42\n"
)

data = yaml.load(doc, Loader=HexLoader)

# The custom resolver fires before / on top of the built-in int resolver and
# yields the same numeric integer values via the explicit !hex constructor.
assert data["mask"] == 255, data["mask"]
assert isinstance(data["mask"], int), type(data["mask"])
assert data["addr"] == 3735928559, data["addr"]
assert data["label"] == "hello", data["label"]
assert isinstance(data["label"], str), type(data["label"])
assert data["decimal"] == 42, data["decimal"]
assert isinstance(data["decimal"], int), type(data["decimal"])

# Confirm the resolver is wired up: parsing a single 0xff scalar via the same
# loader yields the integer 255 (i.e. the regex actually matches).
single = yaml.load("0xff\n", Loader=HexLoader)
assert single == 255, single
assert isinstance(single, int), type(single)

with open(out_path, "w", encoding="utf-8") as fh:
    fh.write(f"mask={data['mask']}\n")
    fh.write(f"addr={data['addr']}\n")
    fh.write(f"single={single}\n")
    fh.write(f"label={data['label']!r}\n")

print("OK")
PYCASE

validator_assert_contains "$tmpdir/out" "mask=255"
validator_assert_contains "$tmpdir/out" "addr=3735928559"
validator_assert_contains "$tmpdir/out" "single=255"
echo "OK"
